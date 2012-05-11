class Journal < ActiveRecord::Base
  has_many                :journal_rows
  belongs_to              :facility
  has_many                :order_details, :through => :journal_rows
  belongs_to              :created_by_user, :class_name => 'User', :foreign_key => :created_by

  validates_uniqueness_of :facility_id, :scope => :is_successful, :if => Proc.new { |j| j.is_successful.nil? }
  validates_presence_of   :reference, :updated_by, :on => :update
  validates_presence_of   :created_by
  validates_presence_of   :journal_date
  has_attached_file       :file,
                          :storage => :filesystem,
                          :url => "#{ENV['RAILS_RELATIVE_URL_ROOT']}/:attachment/:id_partition/:style/:basename.:extension",
                          :path => ":rails_root/public/:attachment/:id_partition/:style/:basename.:extension"

  def amount
    rows = journal_rows
    sum = 0
    rows.each{|row| sum += row.amount if row.amount > 0}
    sum
  end

  def open?
    is_successful.nil?
  end

  def create_journal_rows!(order_details)
    recharge_by_product = {}
    row_errors = []
    # create rows for each transaction
    order_details.each do |od|
      row_errors << "##{od} is already journaled in journal ##{od.journal_id}" if od.journal_id
      account = od.account

      begin
        ValidatorFactory.instance(account.account_number, od.product.account).account_is_open!
      rescue ValidatorError => e
        raise "Account #{account} on order detail ##{od} is invalid. It #{e.message}."
      end

      JournalRow.create!(
        :journal_id      => id,
        :order_detail_id => od.id,
        :amount          => od.total,
        :description     => "##{od}: #{od.order.user}: #{od.fulfilled_at.strftime("%m/%d/%Y")}: #{od.product} x#{od.quantity}",
        :account         => od.product.account
      )
      recharge_by_product[od.product_id] = recharge_by_product[od.product_id].to_f + od.total
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
    d = d.to_date
    if d.month >= 9
      start_fy = Date.new(d.year, 9, 1)
      end_fy   = Date.new(d.year + 1, 9, 1)
    else
      start_fy = Date.new(d.year - 1, 9, 1)
      end_fy   = Date.new(d.year, 9, 1)
    end
    order_details.each do |od|
      return true if (od.fulfilled_at.to_date < start_fy || od.fulfilled_at.to_date >= end_fy)
    end
    false
  end

  def to_s
    id.to_s
  end
end
