class Journal < ActiveRecord::Base
  has_many                :journal_rows
  belongs_to              :facility

  validates_uniqueness_of :facility_id, :scope => :is_successful, :if => Proc.new { |j| j.is_successful.nil? }
  validates_presence_of   :reference, :updated_by, :on => :update
  validates_inclusion_of  :is_successful, :in => [true, false], :on => :update
  has_attached_file       :file,
                          :storage => :filesystem,
                          :url => "#{ActionController::Base.relative_url_root}/:attachment/:id_partition/:style/:basename.:extension",
                          :path => ":rails_root/public/:attachment/:id_partition/:style/:basename.:extension"

  def amount
    rows = journal_rows
    sum = 0
    rows.each{|row| sum += row.amount if row.amount > 0}
    sum
  end
  
  def create_journal_rows_for_account!(account)
    account_txns = account.journalable_facility_transactions(facility)
    account_txns.each do |at|
      od = at.order_detail
      fa = od.product.facility_account
      JournalRow.create!(
        :journal_id      => id,
        :order_detail_id => at.order_detail_id,
        :account_transaction_id => at.id,
        :fund            => account.fund,
        :dept            => account.dept,
        :project         => account.project,
        :activity        => account.activity,
        :program         => account.program,
        :account         => od.product.account,
        :amount          => od.actual_total - od.dispute_resolved_credit.to_f,
        :description     => "Order ##{od}"
      )
      JournalRow.create!(
        :journal_id      => id,
        :order_detail_id => at.order_detail_id,
        :account_transaction_id => at.id,
        :fund            => fa.fund,
        :dept            => fa.dept,
        :project         => fa.project,
        :activity        => fa.activity,
        :program         => fa.program,
        :account         => fa.revenue_account,
        :amount          => (od.actual_total - od.dispute_resolved_credit.to_f) * -1,
        :description     => "Order ##{od}"
      )
    end
  end

  def create_journal_rows_for_accounts!(accounts)
    recharge_by_product = {}

    ## deduct funds from payment source
    accounts.each do |account|
      account_txns = account.journalable_facility_transactions(facility)
      account_txns.each do |at|
        od         = at.order_detail
        txn_amount = od.actual_total - od.dispute_resolved_credit.to_f
        o          = od.order
        NucsValidator.new(account.account_number, od.product.account).account_is_open!
        JournalRow.create!(
          :journal_id      => id,
          :order_detail_id => at.order_detail_id,
          :account_transaction_id => at.id,
          :fund            => account.fund,
          :dept            => account.dept,
          :project         => account.project,
          :activity        => account.activity,
          :program         => account.program,
          :account         => od.product.account,
          :amount          => txn_amount,
          :description     => "##{od}: #{od.order.user}: #{at.created_at.strftime("%m/%d/%Y")}: #{od.product} x#{od.quantity}"
        )
        recharge_by_product[od.product_id] = recharge_by_product[od.product_id].to_f + txn_amount
      end
    end

    ## place funds in recharge chart string, rolled up by product
    recharge_by_product.each_pair do |product_id, total|
      product = Product.find(product_id)
      fa      = product.facility_account
      JournalRow.create!(
        :journal_id      => id,
        :fund            => fa.fund,
        :dept            => fa.dept,
        :project         => fa.project,
        :activity        => fa.activity,
        :program         => fa.program,
        :account         => fa.revenue_account,
        :amount          => total * -1,
        :description     => product.to_s
      )
    end
  end

  def create_payment_transactions! (args = {})
    journal_rows.find(:all, :conditions => ['amount < 0']).each do |row|
      PaymentAccountTransaction.create!(
        :account_id         => row.account_transaction.account_id,
        :facility_id        => facility_id,
        :description        => "Payment for Order ##{row.order_detail}",
        :transaction_amount => row.amount,
        :created_by         => args[:created_by],
        :finalized_at       => Time.zone.now,
        :order_detail_id    => row.order_detail_id,
        :is_in_dispute      => false,
        :reference          => reference
      )
    end
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
end
