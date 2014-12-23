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
            raise I18n.t("activerecord.errors.models.journal.pending_overlap", label: od.to_s, facility: Facility.find(od_facility_id))
          end
          facility_ids_already_in_journal.add(od_facility_id)
        end

        begin
          ValidatorFactory.instance(account.account_number, od.product.account).account_is_open!
        rescue ValidatorError => e
          row_errors << I18n.t("activerecord.errors.models.journal.invalid_account",
            account_number: account.account_number_to_s,
            validation_error: e.message
          )
        end

        JournalRow.create!(journal_row_attributes_from_order_detail(od))
        order_detail_ids << od.id
        recharge_by_product[od.product_id] = recharge_by_product[od.product_id].to_f + od.total if recharge_enabled
      end

      # create rows for each recharge chart string
      recharge_by_product.each_pair do |product_id, total|
        product = Product.find(product_id)
        JournalRow.create!(journal_row_attributes_from_product_and_total(product, total))
      end

      set_journal_for_order_details(order_detail_ids) if row_errors.blank?

      row_errors.uniq
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

    private

    def journal_row_attributes_from_order_detail(order_detail)
      {
        account: order_detail.product.account,
        amount: order_detail.total,
        description: order_detail.long_description,
        journal_id: id,
        order_detail_id: order_detail.id,
      }
    end

    def journal_row_attributes_from_product_and_total(product, total)
      {
        account: product.facility_account.revenue_account,
        amount: total * -1,
        description: product.to_s,
        journal_id: id,
      }
    end
  end

  include NUCore::Database::ArrayHelper
  include Overridable

  attr_accessor :order_details_for_creation

  has_many                :journal_rows
  belongs_to              :facility
  has_many                :order_details, :through => :journal_rows
  belongs_to              :created_by_user, :class_name => 'User', :foreign_key => :created_by

  validates_presence_of   :reference, :updated_by, :on => :update
  validates_presence_of   :created_by
  validates_presence_of   :journal_date
  validate :journal_date_cannot_be_in_future, if: "journal_date.present?"
  validate :must_have_order_details, :on => :create, :if => :order_details_for_creation
  validate :must_not_span_fiscal_years, :on => :create, :if => :has_order_details_for_creation?
  validate :journal_date_cannot_be_before_last_fulfillment, :on => :create, :if => :has_order_details_for_creation?

  before_validation :set_facility_id, :on => :create, :if => :has_order_details_for_creation?
  after_create :create_new_journal_rows, :if => :has_order_details_for_creation?

  has_attached_file       :file,
                          :storage => :filesystem,
                          :url => "#{ENV['RAILS_RELATIVE_URL_ROOT']}/:attachment/:id_partition/:style/:basename.:extension",
                          :path => ":rails_root/public/:attachment/:id_partition/:style/:basename.:extension"
  # The CDF type is set on files created by the spreadsheet gem
  # FIXME CDFV2-corrupt is what's being created on CI
  validates_attachment_content_type :file, content_type: ['application/vnd.ms-excel', 'CDF', 'application/CDFV2-corrupt']

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
    # only sum positive amounts since this is a double entry journal
    journal_rows.inject(0) {|sum, row| sum + (row.amount > 0 ? row.amount : 0)}
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
    reconciled?
  end

  # Use this instead.
  def reconciled?
    if is_successful.nil?
      false
    elsif is_successful? == false
      true
    else
      details = OrderDetail.find(:all, :conditions => ['journal_id = ? AND state <> ?', id, 'reconciled'])
      details.empty? ? true : false
    end
  end

  def order_details_span_fiscal_years?(order_details)
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

  private

  def has_order_details_for_creation?
    @order_details_for_creation.try(:any?)
  end

  def must_not_span_fiscal_years
    errors.add(:base, :fiscal_year_span) if order_details_span_fiscal_years?(@order_details_for_creation)
  end

  def must_have_order_details
    errors.add(:base, :no_orders) if @order_details_for_creation.none?
  end

  def journal_date_cannot_be_in_future
    errors.add(:journal_date, :cannot_be_in_future) if journal_date > Time.zone.now.end_of_day
  end

  def journal_date_cannot_be_before_last_fulfillment
    return unless journal_date.present?
    last_fulfilled = @order_details_for_creation.collect(&:fulfilled_at).max
    errors.add(:journal_date, :cannot_be_before_last_fulfillment) if journal_date.end_of_day < last_fulfilled
  end

  def set_facility_id
    # detect if this should be a multi-facility journal, set facility_id appropriately
    if @order_details_for_creation.collect{|od|od.order.facility_id}.uniq.size > 1
      self.facility_id = nil
    else
      self.facility_id = @order_details_for_creation.first.order.facility_id
    end
  end

  def create_new_journal_rows
    row_errors = create_journal_rows!(@order_details_for_creation)
    if row_errors.any?
      row_errors.each { |e| errors.add(:base, e) }
      self.destroy # so it's treated as a new record
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  def set_journal_for_order_details(order_detail_ids)
    array_slice(order_detail_ids) do |id_slice|
      OrderDetail.where(id: id_slice).update_all(journal_id: self.id)
    end
  end
end
