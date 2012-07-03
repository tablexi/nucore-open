require 'set'

class Journal < ActiveRecord::Base
  module Overridable
    def create_journal_rows!(order_details)
      recharge_by_product = {}
      facility_ids_already_in_journal = Set.new
      order_detail_ids = []
      pending_facility_ids = Journal.facility_ids_with_pending_journals
      row_errors = []
      recharge_enabled=SettingsHelper.feature_on? :recharge_accounts

      # create rows for each transaction
      order_details.each do |od|
        row_errors << "##{od} is already journaled in journal ##{od.journal_id}" if od.journal_id
        account = od.account
        od_facility_id = od.order.facility_id

        # unless we've already encountered this facility_id during
        # this call to create_journal_rows,
        unless facility_ids_already_in_journal.member? od_facility_id

          # check against facility_ids which actually have pending journals
          # in the DB
          if pending_facility_ids.member? od_facility_id
            raise  "This journal date overlaps with a pending journal. You may not generate a new journal until the pending journal is closed."
          end
          facility_ids_already_in_journal.add(od_facility_id)
        end

        begin
          ValidatorFactory.instance(account.account_number, od.product.account).account_is_open!
        rescue ValidatorError => e
          row_errors << "Account #{account} on order detail ##{od} is invalid. #{e.message}."
        end


        JournalRow.create!(
          :journal_id      => id,
          :order_detail_id => od.id,
          :amount          => od.total,
          :description     => "##{od}: #{od.order.user}: #{od.fulfilled_at.strftime("%m/%d/%Y")}: #{od.product} x#{od.quantity}",
          :account         => od.product.account
        )
        order_detail_ids << od.id
        recharge_by_product[od.product_id] = recharge_by_product[od.product_id].to_f + od.total if recharge_enabled
      end

      # create rows for each recharge chart string
      recharge_by_product.each_pair do |product_id, total|
        product = Product.find(product_id)
        fa      = product.facility_account
        JournalRow.create!(
          :journal_id      => id,
          :account         => fa.revenue_account,
          :amount          => total * -1,
          :description     => product.to_s
        )
      end

      OrderDetail.update_all(['journal_id = ?', self.id], ['id IN (?)', order_detail_ids]) unless row_errors.present?

      return row_errors
    end


    def create_spreadsheet
      rows = journal_rows
      return false if rows.empty?

      # write journal spreadsheet to tmp directory
      # temp_file   = Tempfile.new("journalspreadsheet")
      temp_file   = File.new("#{Dir::tmpdir}/journal.spreadsheet.#{Time.zone.now.strftime("%Y%m%dT%H%M%S")}.xls", "w")
      output_file = JournalSpreadsheet.write_journal_entry(rows, :output_file => temp_file.path)
      # add/import journal spreadsheet
      status      = add_spreadsheet(output_file)
      # remove temp file
      File.unlink(temp_file.path) rescue nil
      status
    end
  end

  include Overridable

  has_many                :journal_rows
  belongs_to              :facility
  has_many                :order_details, :through => :journal_rows
  belongs_to              :created_by_user, :class_name => 'User', :foreign_key => :created_by

  validates_presence_of   :reference, :updated_by, :on => :update
  validates_presence_of   :created_by
  validates_presence_of   :journal_date
  has_attached_file       :file,
                          :storage => :filesystem,
                          :url => "#{ENV['RAILS_RELATIVE_URL_ROOT']}/:attachment/:id_partition/:style/:basename.:extension",
                          :path => ":rails_root/public/:attachment/:id_partition/:style/:basename.:extension"


  # Digs up journals pertaining to the passed in facilities
  #
  # == Parameters
  #
  # facilities::
  #   enumerable of facilities (usually ones which the user has access to)
  #
  # include_multi::
  #   include multi-facility journals in the results?
  def self.for_facilities(facilities, include_multi = false)
    allowed_ids = facilities.collect(&:id)

    if include_multi
      Journal.includes(:journal_rows => {:order_detail => :order}).where('orders.facility_id IN (?)', allowed_ids).select('journals.*')
    else
      Journal.where(:facility_id => allowed_ids)
    end
  end

  def self.facility_ids_with_pending_journals
    # use AR to build the SQL for pending journals
    pending_facility_ids_sql = Journal.joins(:order_details => :order).where(:is_successful => nil).select("DISTINCT orders.facility_id").to_sql

    # run it and get the results back (a list)
    pending_facility_ids = Journal.connection.select_values(pending_facility_ids_sql)

    return pending_facility_ids
  end

  def facility_ids
    if facility_id?
      [facility_id]
    else
        order_details.joins(:order).
        select('orders.facility_id').
        collect(&:facility_id).
        uniq
    end
  end

  def facility_abbreviations
    Facility.where(:id => self.facility_ids).collect(&:abbreviation)
  end

  def amount
    rows = journal_rows
    sum = 0
    rows.each{|row| sum += row.amount if row.amount > 0}
    sum
  end

  def open?
    is_successful.nil?
  end

  def add_spreadsheet(file_path)
    return false if !File.exists?(file_path)
    update_attribute(:file, File.open(file_path))
  end

  def status_string
    if is_successful.nil?
      'Pending'
    elsif is_successful? == false
      'Failed'
    else
      is_reconciled? ? 'Successful, reconciled' : 'Successful, not reconciled'
    end
  end

  def is_reconciled?
    if is_successful.nil?
      false
    elsif is_successful? == false
      true
    else
      details = OrderDetail.find(:all, :conditions => ['journal_id = ? AND state <> ?', id, 'reconciled'])
      details.empty? ? true : false
    end
  end

  def self.order_details_span_fiscal_years?(order_details)
    d = order_details.first.fulfilled_at
    start_fy = SettingsHelper::fiscal_year_beginning(d)
    end_fy = SettingsHelper::fiscal_year_end(d)
    order_details.each do |od|
      return true if (od.fulfilled_at < start_fy || od.fulfilled_at >= end_fy)
    end
    false
  end

  def to_s
    id.to_s
  end
end
