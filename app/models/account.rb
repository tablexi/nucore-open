class Account < ActiveRecord::Base

  module Overridable
    def price_groups
      (price_group_members.collect{ |pgm| pgm.price_group } + (owner_user ? owner_user.price_groups : [])).flatten.uniq
    end
  end

  include Overridable
  include Accounts::AccountNumberSectionable
  include DateHelper

  has_many   :account_users, :inverse_of => :account
  # Using a basic hash doesn't work with the `owner_user` :through association. It would
  # only include the last item in the hash as part of the scoping.
  # TODO Consider changing when we get to Rails 4.
  has_one    :owner, class_name: 'AccountUser', conditions: "account_users.user_role = '#{AccountUser::ACCOUNT_OWNER}' AND account_users.deleted_at IS NULL"
  has_one    :owner_user, through: :owner, source: :user
  has_many   :business_admins, :class_name => 'AccountUser', :conditions => {:user_role => AccountUser::ACCOUNT_ADMINISTRATOR, :deleted_at => nil}
  has_many   :price_group_members
  has_many   :order_details
  has_many   :orders
  has_many   :statements, :through => :order_details
  belongs_to :affiliate
  accepts_nested_attributes_for :account_users

  scope :active, lambda {{ :conditions => ['expires_at > ? AND suspended_at IS NULL', Time.zone.now] }}

  validates_presence_of :account_number, :description, :expires_at, :created_by, :type
  validates_length_of :description, :maximum => 50

  validate do |acct|
    # a current account owner if required
    # don't use a scope so we can validate on nested attributes
    unless acct.account_users.any?{ |au| au.deleted_at.nil? && au.user_role == AccountUser::ACCOUNT_OWNER }
      acct.errors.add(:base, "Must have an account owner")
    end
  end

  def add_or_update_member(user, new_role, session_user)
    Account.transaction do
      # expire old owner if new
      if new_role == AccountUser::ACCOUNT_OWNER
        # expire old owner record
        @old_owner = self.owner
        if @old_owner
          @old_owner.deleted_at = Time.zone.now
          @old_owner.deleted_by = session_user.id
          @old_owner.save!
        end
      end

      # find non-deleted record for this user and account or init new one
      # deleted_at MUST be nil to preserve existing audit trail
      @account_user = AccountUser.find_or_initialize_by_account_id_and_user_id_and_deleted_at(
        self.id,
        user.id,
        nil
      )
      # set (new?) role
      @account_user.user_role = new_role
      # set creation information
      @account_user.created_by = session_user.id

      self.account_users << @account_user

      raise ActiveRecord::Rollback unless self.save
    end

    return @account_user
  end

  def facility
    nil
  end


  def self.limited_to_single_facility?
    AccountManager::FACILITY_ACCOUNT_CLASSES.include? self.name
  end

  def self.for_facility(facility)
    accounts = scoped

    unless facility.all_facility?
      accounts = accounts.where("accounts.type in (:allow_all) or (accounts.type in (:limit_one) and accounts.facility_id = :facility)",
            {:allow_all => AccountManager::GLOBAL_ACCOUNT_CLASSES,
              :limit_one => AccountManager::FACILITY_ACCOUNT_CLASSES,
              :facility => facility})
    end

    accounts
  end

  def self.for_user(user)
    joins(:account_users).where("account_users.user_id = ?", user.id)
  end

  def self.for_order_detail(order_detail)
    for_user(order_detail.user)
    .where("accounts.facility_id IS NULL OR accounts.facility_id = ?", order_detail.facility.id)
  end

  # find all accounts that have ordered fror a facility
  def self.has_orders_for_facility(facility)
    ids = OrderDetail.for_facility(facility).select("distinct order_details.account_id").collect(&:account_id)
    where(:id => ids)
  end

  def facilities
    if facility_id
      # return a relation
      Facility.active.where(:id => facility_id)
   else
      Facility.active
    end
  end

  def type_string
    I18n.t("activerecord.models.#{self.class.to_s.underscore}.one", :default => self.class.model_name.human)
  end

  def <=>(obj)
    account_number <=> obj.account_number
  end

  def owner_user_name
    owner_user.try(:name) || ""
  end

  def business_admin_users
    self.business_admins.collect{|au| au.user}
  end

  def notify_users
    [owner_user] + business_admin_users
  end

  def suspend!
    self.suspended_at = Time.zone.now
    self.save!
  end

  def unsuspend!
    self.suspended_at = nil
    self.save!
  end

  def display_status
    if suspended?
      I18n.t("activerecord.models.account.statuses.suspended")
    else
      I18n.t("activerecord.models.account.statuses.active")
    end
  end

  def suspended?
    !self.suspended_at.blank?
  end

  def expired?
    expires_at && expires_at <= Time.zone.now
  end

  def formatted_expires_at
    expires_at.try(:strftime, "%m/%d/%Y")
  end

  def formatted_expires_at=(str)
    self.expires_at = parse_usa_date(str) if str
  end

  def account_pretty
    to_s true
  end

  def account_list_item
    "#{account_number} #{description}"
  end

  def validate_against_product(product, user)
    # does the facility accept payment method?
    return "#{product.facility.name} does not accept #{self.type_string} payment" unless product.facility.can_pay_with_account?(self)

    # does the product have a price policy for the user or account groups?
    return "The #{self.type_string} has insufficient price groups" unless product.can_purchase?((self.price_groups + user.price_groups).flatten.uniq.collect {|pg| pg.id})

    # check chart string account number
    if self.is_a?(NufsAccount)
      accts=product.is_a?(Bundle) ? product.products.collect(&:account) : [ product.account ]
      accts.uniq.each {|acct| return "The #{self.type_string} is not open for the required account" unless self.account_open?(acct) }
    end

    return nil
  end

  def can_reconcile?(order_detail)
    order_detail.statement_id.present?
  end

  def self.need_statements (facility)
    # find details that are complete, not yet statemented, priced, and not in dispute
    details = OrderDetail.need_statement(facility)
    find(details.collect{ |detail| detail.account_id }.uniq || [])
  end

  def self.need_notification (facility)
    # find details that are complete, not yet notified, priced, and not in dispute
    details = OrderDetail.for_facility(facility).need_notification
    find(details.collect{ |detail| detail.account_id }.uniq || [])
  end

  def facility_balance (facility, date=Time.zone.now)
    details = OrderDetail.for_facility(facility).complete.where('order_details.fulfilled_at <= ? AND price_policy_id IS NOT NULL AND order_details.account_id = ?', date, id)
    details.collect{|od| od.total}.sum.to_f
  end

  def unreconciled_order_details(facility)
    OrderDetail.account_unreconciled(facility, self)
  end

  def unreconciled_total(facility, order_details = unreconciled_order_details(facility))
    order_details.inject(0) do |balance, order_detail|
      cost = order_detail.cost_estimated? ? order_detail.estimated_total : order_detail.actual_total
      balance += cost if cost
      balance
    end
  end

  def latest_facility_statement (facility)
    statements.latest(facility).first
  end

  def update_order_details_with_statement (statement)
    details=order_details.joins(:order).
                          where('orders.facility_id = ? AND order_details.reviewed_at < ? AND order_details.statement_id IS NULL', statement.facility.id, Time.zone.now).
                          readonly(false).
                          all

    details.each {|od| od.update_attributes({:reviewed_at => Time.zone.now+Settings.billing.review_period, :statement => statement }) }
  end

  def can_be_used_by?(user)
    !account_users.where('user_id = ? AND deleted_at IS NULL', user.id).first.nil?
  end

  def is_active?
    expires_at > Time.zone.now && suspended_at.nil?
  end

  def account_number_to_s
    self.account_number.to_s
  end

  def to_s(with_owner = false, flag_suspended = true)
    desc = "#{description} / #{account_number_to_s}"
    desc += " / #{owner_user_name}" if with_owner && owner_user.present?
    desc += " (#{display_status.upcase})" if flag_suspended && suspended?
    desc
  end

  def affiliate_to_s
    return unless affiliate
    affiliate_name = affiliate.name
    affiliate_name += ": #{affiliate_other}" if affiliate == Affiliate.OTHER
    affiliate_name
  end

  def description_to_s
    if suspended?
      "#{description} (#{display_status.upcase})"
    else
      description
    end
  end

end
