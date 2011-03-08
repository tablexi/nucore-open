class Account < ActiveRecord::Base
  has_many   :account_users
  has_one    :owner, :class_name => 'AccountUser', :conditions => {:user_role => 'Owner', :deleted_at => nil}
  has_many   :business_admins, :class_name => 'AccountUser', :conditions => {:user_role => 'Business Administrator', :deleted_at => nil}
  has_many   :price_group_members
  has_many   :account_transactions
  has_many   :payment_account_transactions
  has_many   :purchase_account_transactions
  has_many   :credit_account_transactions
  has_many   :statements, :through => :account_transactions
  accepts_nested_attributes_for :account_users

  named_scope :active, lambda {{ :conditions => ['expires_at > ? AND suspended_at IS NULL', Time.zone.now] }}
  named_scope :for_facility, lambda { |facility| { :conditions => ["type <> 'PurchaseOrderAccount' OR (type = 'PurchaseOrderAccount' AND facility_id = ?)", facility.id] }}

  validates_presence_of :account_number, :description, :expires_at, :created_by, :type

  def validate
    # an account owner if required
    if !self.account_users.any?{ |au| au.user_role == 'Owner' }
      self.errors.add_to_base("Must have an account owner")
    end
  end

  def type_string
    case self
      when PurchaseOrderAccount
        'Purchase Order'
      when CreditCardAccount
        'Credit Card'
      when NufsAccount
        'Chart String'
      else
        'Account'
    end
  end

  def <=>(obj)
    account_number <=> obj.account_number
  end

  def owner_user
    self.owner.user
  end

  def business_admin_users
    self.business_admins.collect{|au| au.user}
  end

  def notify_users
    [owner_user] + business_admin_users
  end

  def suspend!
    self.suspended_at = Time.zone.now
    self.save
  end

  def unsuspend!
    self.suspended_at = nil
    self.save
  end

  def suspended?
    !self.suspended_at.blank?
  end

  def account_pretty
    "#{description} (#{account_number})"
  end

  def validate_against_product(product, user)
    # does the facility accept payment method?
    return "#{product.facility.name} does not accept #{self.type_string} payment" unless product.facility.can_pay_with_account?(self)

    # does the product have a price policy for the user or account groups?
    return "The #{self.type_string} has insufficient price groups" unless product.can_purchase?((self.price_groups + user.price_groups).flatten.uniq.collect {|pg| pg.id})

    # check chart string account number
    return "The #{self.type_string} is not open for the required account" if self.is_a?(NufsAccount) && !self.account_open?(product.account)
  end

  def self.need_statements (facility)
    sql = "SELECT DISTINCT account_id FROM account_transactions WHERE facility_id = #{facility.id} AND statement_id IS NULL AND is_in_dispute = 0"
    ats = AccountTransaction.find_by_sql(sql) #not a real AT object; only account_id
    find(ats.collect{|at| at.account_id} || [])
  end

  def facility_balance (facility)
    at = account_transactions.find(:first,
        :conditions => ['facility_id = ? AND finalized_at <= ?', facility.id, Time.zone.now],
        :select => "SUM(transaction_amount) AS balance" )
    at.nil? ? 0 : at.balance.to_f
  end

  def facility_recent_payment_balance (facility)
    at = account_transactions.find(:first,
        :conditions => ["(statement_id IS NULL OR invoice_date >= ?) AND account_transactions.facility_id = ? AND (type = 'PaymentAccountTransaction' OR type = 'CreditAccountTransaction')", Time.zone.now, facility.id],
        :select => 'SUM(transaction_amount) AS balance',
        :joins => 'LEFT JOIN statements ON statement_id = statements.id' )
    at.nil? ? 0 : at.balance.to_f
  end
  
  def facility_recent_purchase_balance (facility)
    at = purchase_account_transactions.find(:first,
        :conditions => ["(statement_id IS NULL OR invoice_date >= ?) AND account_transactions.facility_id = ?", Time.zone.now, facility.id],
        :select => 'SUM(transaction_amount) AS balance',
        :joins => 'LEFT JOIN statements ON statement_id = statements.id' )
    at.nil? ? 0 : at.balance.to_f    
  end

  def statement_payment_balance (statement)
    at = account_transactions.find(:first,
        :conditions => ["statement_id = ? AND (type = 'PaymentAccountTransction' OR type = 'CreditAccountTransactions')", statement.id],
        :select => 'SUM(transaction_amount) AS balance' )
    at.nil? ? 0 : at.balance.to_f
  end
  
  def statement_purchase_balance (statement)
    at = purchase_account_transactions.find(:first,
        :conditions => ["statement_id = ?", statement.id],
        :select => 'SUM(transaction_amount) AS balance' )
    at.nil? ? 0 : at.balance.to_f    
  end

  def facility_balance_including_pending (facility)
    at = account_transactions.find(:first,
        :conditions => ['facility_id = ? AND is_in_dispute = ?', facility.id, false],
        :select => "SUM(transaction_amount) AS balance" )
    at.nil? ? 0 : at.balance.to_f
  end

  def facility_balance_on_date (facility, datetime)
    at = account_transactions.find(:first,
        :conditions => ['facility_id = ? AND (finalized_at <= ?)', facility.id, datetime],
        :select => "SUM(transaction_amount) AS balance" )
    at.nil? ? 0 : at.balance.to_f
  end

  def latest_facility_statement (facility)
    statements.latest(facility).first
  end

  def update_account_transactions_with_statement (statement)
    AccountTransaction.update_all({:finalized_at => statement.invoice_date, :statement_id => statement.id}, "account_id = #{id} AND facility_id = #{statement.facility_id} AND statement_id IS NULL")
  end

  def can_be_used_by?(user)
    !(account_users.find(:first, :conditions => ['user_id = ? AND deleted_at IS NULL', user.id]).nil?)
  end

  def is_active?
    expires_at > Time.zone.now && suspended_at.nil?
  end

  def to_s
    string = "#{description} (#{account_number})"
    if self.class == PurchaseOrderAccount
      string += " - #{facility.name}"
    end
    string
  end
  
  def price_groups
    (price_group_members.collect{ |pgm| pgm.price_group } + owner_user.price_groups).flatten.uniq
  end
end
