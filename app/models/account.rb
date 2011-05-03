class Account < ActiveRecord::Base
  has_many   :account_users
  has_one    :owner, :class_name => 'AccountUser', :conditions => {:user_role => AccountUser::ACCOUNT_OWNER, :deleted_at => nil}
  has_many   :business_admins, :class_name => 'AccountUser', :conditions => {:user_role => AccountUser::ACCOUNT_ADMINISTRATOR, :deleted_at => nil}
  has_many   :price_group_members
  has_many   :order_details
  has_many   :statements, :through => :order_details
  accepts_nested_attributes_for :account_users

  named_scope :active, lambda {{ :conditions => ['expires_at > ? AND suspended_at IS NULL', Time.zone.now] }}
  named_scope :for_facility, lambda { |facility| { :conditions => ["type <> 'PurchaseOrderAccount' OR (type = 'PurchaseOrderAccount' AND facility_id = ?)", facility.id] }}

  validates_presence_of :account_number, :description, :expires_at, :created_by, :type
  validates_length_of :description, :maximum => 50

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
    self.owner.user if owner
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
    sql=<<-SQL
      SELECT DISTINCT
        od.account_id
      FROM
        order_details od, orders o
      WHERE
        o.facility_id = #{facility.id}
        AND od.order_id=o.id
        AND od.statement_id IS NULL
        AND (od.dispute_at IS NULL OR (od.dispute_at IS NOT NULL AND od.dispute_resolved_at IS NOT NULL))
    SQL
    ats = OrderDetail.find_by_sql(sql) #not a real AT object; only account_id
    find(ats.collect{|at| at.account_id} || [])
  end

  def facility_balance (facility, date=Time.zone.now)
    at = order_details.find(:first,
        :joins => "INNER JOIN orders ON orders.id=order_details.order_id INNER JOIN statements ON statements.id=order_details.statement_id INNER JOIN statement_rows ON statements.id=statement_rows.statement_id",
        :conditions => ['orders.facility_id = ? AND statements.finalized_at <= ?', facility.id, date],
        :select => "SUM(statement_rows.amount) AS balance" )
    at.nil? ? 0 : at.balance.to_f
  end

  def facility_balance_on_date (facility, datetime)
    return facility_balance(facility, datetime)
  end

  def unreconciled_total(facility)
    details=order_details.find(:all,
      :joins => :order,
      :conditions => [ 'orders.facility_id = ? AND order_details.account_id = ?', facility.id, id ]
    )

    unreconciled_total=0

    details.each do |od|
      total=od.cost_estimated? ? od.estimated_total : od.actual_total
      unreconciled_total += total if total
    end

    unreconciled_total
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
    (price_group_members.collect{ |pgm| pgm.price_group } + (owner_user ? owner_user.price_groups : [])).flatten.uniq
  end
end
