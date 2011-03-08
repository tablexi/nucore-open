class NufsAccount < Account
  include Validations
  
  validates_format_of     :account_number, :with => NucsValidator::NUCS_PATTERN, :message => "must be in the format 123-1234567-12345678-12-1234-1234; project, activity, program, and chart field 1 are optional"
  validates_uniqueness_of :account_number, :message => "already exists"

  def validate
    validate_chartstring
  end

#  def faclity_balance_grouped_by_transaction(facility)
#    prev_payment = self.payment_account_transactions.find(:first, :order => 'finalized_at DESC')
#    if prev_payment
#      last_journal_date = prev_payment.journal.created_at
#      at = account_transactions.find(:all, :conditions => ['account_id = ? AND facility_id = ? AND finalized_at > ? AND finalized_at <= ?', id, facility.id, last_journal_date, Time.zone.now], :select => "SUM(transaction_amount) AS balance, order_detail_id, facility_account_id", :group => "facility_account_id, order_detail_id HAVING SUM(transaction_amount) > 0")
#    else
#      at = account_transactions.find(:all, :conditions => ['account_id = ? AND facility_id = ? AND finalized_at <= ?', id, facility.id, Time.zone.now], :select => "SUM(transaction_amount) AS balance, order_detail_id, facility_account_id", :group => "facility_account_id, order_detail_id HAVING SUM(transaction_amount) > 0")
#    end
#  end
  
  # TODO: where is this used and does it need to be updated to respect invoice dates?
  def journalable_facility_transactions(facility)
    ats = self.account_transactions.find(
              :all,
              :conditions => ['facility_id = ? AND finalized_at <= ?', facility.id, Time.zone.now],
              :select => "SUM(transaction_amount) AS total_amount, order_detail_id, MIN(id) AS id, MIN(created_at) as created_at",
              :group => 'order_detail_id HAVING SUM(transaction_amount) > 0')
  end
  
  def set_expires_at
    begin
      self.expires_at = NucsValidator.new(account_number).latest_expiration
    rescue NucsError
    end
  end
  
  def account_open? (account_num)
    begin
      NucsValidator.new(account_number, account_num).account_is_open!
    rescue NucsError
      return false
    end

    return true
  end
end
