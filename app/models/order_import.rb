require 'date_helper' # parse_usa_date
require 'csv_helper'

USER_HEADER             = "Netid / Email"
CHART_STRING_HEADER     = "Chart String"
PRODUCT_NAME_HEADER     = "Product Name"
QUANTITY_HEADER         = "Quantity"
ORDER_DATE_HEADER       = "Order Date"
FULFILLMENT_DATE_HEADER = "Fulfillment Date"
ERRORS_HEADER           = "Errors"

HEADERS = [USER_HEADER, CHART_STRING_HEADER, PRODUCT_NAME_HEADER, QUANTITY_HEADER, ORDER_DATE_HEADER, FULFILLMENT_DATE_HEADER, ERRORS_HEADER]

class OrderImport < ActiveRecord::Base
  include DateHelper
  include CSVHelper
  
  belongs_to :upload_file, :class_name => 'StoredFile', :dependent => :destroy
  belongs_to :error_file, :class_name => 'StoredFile', :dependent => :destroy
  belongs_to :creator, :class_name => 'User', :foreign_key => :created_by

  validates_presence_of :upload_file_id, :created_by
  attr_accessor :facility
  attr_accessor :error_report
  attr_accessor :order_id_cache_by_order_key

  #
  # Tries to import the orders defined in #upload_file.
  # [_returns_]
  #   An OrderImport::Result object
  # [_raises_]
  #   Any encountered error
  def process!
    result = Result.new

    upload_file_path = upload_file.file.path
    
    if fail_on_error
      result = handle_save_nothing_on_error(upload_file_path, result)
    else
      result = handle_save_clean_orders(upload_file_path, result)
    end

    # save the error report if necessary
    if result.failed?
      self.error_file = StoredFile.new(
        :file       => StringIO.new(self.error_report),
        :file_type  => "import_error",
        :name => "error_report.csv",
        :created_by => creator.id
      )

      self.error_file.file.instance_write(:file_name, "error_report.csv")
    end
    self.save!
 
    return result
  end

  def handle_save_nothing_on_error(upload_file_path, result)
    # loop over non-header rows
    Order.transaction do
      CSV.open(upload_file_path, :headers => true).each do |row|
        row_errors = errors_for(row)

        # write to error_report in case an error occurs
        write_to_error_report(row, row_errors.join(", "))

        if row_errors.length > 0 
          result.failures += 1
        else
          result.successes += 1
        end
      end

      raise ActiveRecord::Rollback if result.failed?
    end

    unless result.failed?
        # send notifications
        order_ids = @order_id_cache_by_order_key.values()
        orders    = Order.where(:id => order_ids)
        orders.each do |order|
          Notifier.order_receipt(:user => order.user, :order => order).deliver
        end

        # we didn't fail, throw away the error report/file
        self.error_file = nil
        self.error_report = nil
    end

    return result
  end

  def handle_save_clean_orders(upload_file_path, result)
    # build rows_by_order_key ( order_key => [row+] )
    rows_by_order_key = Hash.new{|h, k| h[k] = []} 
    CSV.open(upload_file_path, :headers => true).each do |row|
      order_key = [row[USER_HEADER], row[CHART_STRING_HEADER], row[ORDER_DATE_HEADER]]
      rows_by_order_key[order_key] << row
    end

    # loop over the order keys
    rows_by_order_key.each do |order_key, rows|
      # reset error mode flag
      in_error_mode = false

      # one transaction per order_key (per order effectively)
      Order.transaction do
        rows.each do |row|
          row_errors = errors_for(row)
          
          # one row errored out
          if row_errors.length > 0 || in_error_mode
            write_to_error_report(row, row_errors.join(", "))
            # make sure we stay in error mode
            in_error_mode ||= true

            result.failures  += 1
          else
            result.successes += 1
          end
        end

        raise ActiveRecord::Rollback if in_error_mode
      end

      unless in_error_mode
        # send out notifications
        order = get_cached_order(order_key)
        Notifier.order_receipt(:user => order.user, :order => order).deliver
      end
    end

    return result
  end

  # FIXME: buffers all error rows in a string in memory
  # should be storing to file instead
  def write_to_error_report(row, errors)
    if self.error_report.nil?
      self.error_report = HEADERS.join(",") + "\n"
    end

    self.error_report += (row << [ERRORS_HEADER, errors]).to_csv
  end

  def get_cached_order(order_key)
    unless defined? @order_id_cache_by_order_key
      @order_id_cache_by_order_key = {}
    end
    
    if order_id = @order_id_cache_by_order_key[order_key]
      return Order.find(order_id)
    else
      return nil
    end
  end

  def cache_order(order_key, order_id)
    @order_id_cache_by_order_key[order_key] = order_id
  end


  def errors_for(row)
    errs = []
    account_number = row[CHART_STRING_HEADER].strip

    # convert quantity
    qty = row[QUANTITY_HEADER].to_i

    # convert dates
    begin
      fulfillment_date = parse_usa_date(row[FULFILLMENT_DATE_HEADER])
    rescue ArgumentError
      errs << "Invalid Fullfillment Date"
    end 
    
    begin
      order_date = parse_usa_date(row[ORDER_DATE_HEADER])
    rescue ArgumentError
      errs << "Invalid Order Date"
    end 
    
    # get user
    unless user = User.find_by_username(row[USER_HEADER].strip)
      errs << "invalid username"
    end

    # get product
    unless product = facility.items.find_by_name(row[PRODUCT_NAME_HEADER].strip)
      errs << "couldn't find product by name: " + row[PRODUCT_NAME_HEADER]
    end

    # cant find a 
    if user && product
      # account finder from OrdersController#choose_account
      if account = user.accounts.for_facility(product.facility).active.find_by_account_number(account_number)
        # account checker from OrdersController#choose_account
        error = account.validate_against_product(product, user)
        errs << error if error
      else
        errs << "Can't find account"
      end
    end


    if errs.length == 0
      order_key = [row[USER_HEADER], row[CHART_STRING_HEADER], row[ORDER_DATE_HEADER]]
      
      # basic error cases over.... try creating the order / order details
      unless order = get_cached_order(order_key)
        order = Order.create!(
          :facility   => facility,
          :account    => account,
          :user       => user,
          :created_by_user => creator,
          :ordered_at => order_date,
          :account    => account,
          :order_import => self
        )
      end

      # add product (creates order details or raises exceptions)
      ods = order.add(product, qty)
      
      # skip validation / purchase
      unless order.purchased?
        if order.validate_order!
          unless order.purchase!
            errs << "Couldn't purchase order"
          end
        else
          errs << "Couldn't validate order"
        end
        
      end

      ods.each do |od|
        od.backdate_to_complete!(fulfillment_date)
      end

      cache_order(order_key, order.id) if errs.length == 0

    end

    return errs
  end

    # Process each line of CSV file in #upload_file.
    #
    # if fail_on_error
    #   If an error is encountered create the exact
    #   same CSV with the error annotated in a new error column.
    #   Save error file to #error_file.
    # else
    #   Save all valid orders and keep track of any failures.
    #   At end of processing create a #error_file out of the failures.
    #   Include each failed line with the error annotated in a new error column.
    # end
    #
    # Be sure to honor #send_receipts
    #
  
  class Result
    attr_accessor :successes, :failures

    def initialize
      self.successes, self.failures=0, 0
    end

    def failed?
      failures > 0
    end

    def blank?
      successes == 0 && failures == 0
    end
  end
end
