class AccountTransaction < ActiveRecord::Base

  belongs_to :account
  belongs_to :facility
  belongs_to :order_detail
  belongs_to :facility_account
  belongs_to :statement

  validates_numericality_of   :facility_id, :account_id, :created_by, :only_integer => true
  validates_presence_of       :type

  named_scope :facility_recent, lambda { |facility|
                                  { :conditions => ['(statement_id IS NULL OR invoice_date > ?) AND account_transactions.facility_id = ?', Time.zone.now, facility.id],
                                    :joins => 'LEFT JOIN statements ON statement_id = statements.id' }
                                  }
  named_scope :finalized, lambda {{ :conditions => ['finalized_at < ?', Time.zone.now] }}

  def can_dispute?
    return false unless self.statement_id && self.finalized_at && self.finalized_at > Time.zone.now
    # make sure this is a purchase account transaction and that the order has not been disputed before and the order is complete
    od = order_detail
    return false unless self.is_a?(PurchaseAccountTransaction) && od && od.dispute_resolved_at.nil? && od.dispute_at.nil? && od.complete?
    
    # check to make sure this is the most recent transaction for this order
    most_recent_txn = PurchaseAccountTransaction.find(:first, :conditions => {:order_detail_id => od.id}, :order => 'created_at DESC')
    most_recent_txn.id == most_recent_txn.id
  end

  def type_string
    case self
      when PurchaseAccountTransaction
        'Purchase Account'
      when PaymentAccountTransaction
        'Payment Account'
      when CreditAccountTransaction
        'Credit Account'
      else
        'Transaction'
    end
  end

  def status_string
    if is_in_dispute?
      'In Dispute'
    elsif finalized_at.nil?
      'Pending Notification'
    elsif finalized_at <= Time.zone.now
      'Finalized'
    elsif finalized_at > Time.zone.now
      'Customer Review'
    else
      ''
    end
  end
end
