# frozen_string_literal: true

class User < ApplicationRecord

  include ::Users::Roles
  include Nucore::Database::WhereIdsIn

  # ldap_authenticatable is included via a to_prepare hook if ldap is enabled
  devise :database_authenticatable, :encryptable, :trackable, :recoverable, :lockable, :timeoutable, :secure_validatable

  has_many :account_users, -> { where(deleted_at: nil) }
  has_many :accounts, through: :account_users
  has_many :orders
  has_many :order_details, through: :orders
  has_many :reservations, through: :order_details
  has_many :price_group_members, class_name: "UserPriceGroupMember", dependent: :destroy
  has_many :price_groups, -> { SettingsHelper.feature_on?(:user_based_price_groups) ? distinct : none }, through: :price_group_members
  has_many :product_users
  has_many :products, through: :product_users
  has_many :notifications
  has_many :assigned_order_details, class_name: "OrderDetail", foreign_key: "assigned_user_id"
  has_many :user_roles, -> { extending UserRole::AssociationExtension }, dependent: :destroy
  has_many :facilities, through: :user_roles
  has_many :training_requests, dependent: :destroy
  has_many :stored_files, through: :order_details, class_name: "StoredFile"
  has_many :file_uploads, class_name: "StoredFile" # accessed in the UI on the user's Docs tab
  has_many :log_events, as: :loggable
  has_many :user_preferences, dependent: :destroy

  validates_presence_of :username, :first_name, :last_name

  validates :email, presence: true, email_format: true
  validates_uniqueness_of :email, case_sensitive: false
  validates :username, uniqueness: { case_sensitive: false }
  validates :suspension_note, length: { maximum: 255 }

  accepts_nested_attributes_for :account_users, allow_destroy: true

  # Gem ldap_authenticatable expects User to respond_to? :login. For us that's #username.
  alias_attribute :login, :username

  # TODO: This allows downstream forks that reference deactivated_at to not break. Once
  # those are cleaned up, remove me.
  alias_attribute :deactivated_at, :suspended_at

  # Gem ldap_authenticatable expects User to respond_to? :ldap_attributes. For us should return nil.
  attr_accessor :ldap_attributes

  cattr_accessor(:default_price_group_finder) { ::Users::DefaultPriceGroupSelector.new }

  scope :authenticated_by_netid, -> { where(encrypted_password: nil, password_salt: nil) }
  scope :active, -> { unexpired.where(suspended_at: nil) }
  scope :unexpired, -> { where(expired_at: nil) }

  scope :with_global_roles, -> { where(id: UserRole.global.select("distinct user_id")) }
  scope :with_recent_orders, ->(facility) { distinct.joins(:order_details).merge(OrderDetail.recent.for_facility(facility)) }
  scope :sort_last_first, -> { order(Arel.sql("LOWER(users.last_name), LOWER(users.first_name)")) }

  # This method is only used by devise-security to determine
  # whether or not password validations should run.
  # A better name would be password_validations_required?
  # but that's just my humble opinion.
  # See https://github.com/devise-security/devise-security/blob/master/lib/devise-security/models/secure_validatable.rb#L54
  #
  # By default passwords are validated for new records,
  # or when the password or password_confirmation are being set.
  # We override here because we only want to run validations
  # for persisted, locally authenticated users.
  # New locally authenticated users get a valid password set
  # by UserForm#set_password.
  def password_required?
    return false unless persisted? && authenticated_locally?

    super
  end

  # finds all user role mappings for a this user in a facility
  def facility_user_roles(facility)
    UserRole.where(facility_id: facility.id, user_id: id)
  end

  #
  # Returns true if the user is authenticated against nucore's
  # user table, false if authenticated by an external system
  def authenticated_locally?
    encrypted_password.present? && password_salt.present?
  end

  def password_updatable?
    authenticated_locally?
  end

  # Runs various validation checks and then saves the new password.
  #
  # Returns: Boolean
  #
  # The order of various validity checks here is important,
  # see numbered comments below.
  def update_password_confirm_current(params)
    # 1) Must run this check before the password is set to a new value,
    # but we can't set errors until after calling #valid?
    current_password_valid = valid_password?(params[:current_password])

    # 2) Bail if somehow the user should be using SSO
    unless password_updatable?
      errors.add(:base, :password_not_updatable)
      return false
    end

    # 3) Set the password so devise-security can check password complexity
    self.password = params[:password].strip
    valid? # clears any existing errors

    # 4) Add more validation errors as needed
    errors.add(:current_password, :incorrect) unless current_password_valid
    errors.add(:password, :empty) if params[:password].blank?
    errors.add(:password, :password_too_short) if params[:password] && params[:password].strip.length < 10
    errors.add(:password_confirmation, :confirmation) if params[:password] != params[:password_confirmation]

    if errors.empty?
      clear_reset_password_token
      save!
      return true
    else
      return false
    end
  end

  # Find the users for a facility
  def self.find_users_by_facility(facility)
    facility
      .users
      .sort_last_first
  end

  #
  # A cart is an order. This method finds this user's order.
  # [_created_by_user_]
  #   The user that created the order we want. +self+ is
  #   inferred if left nil.
  # [_find_existing_]
  #   true if we want to look in the DB for an order to add
  #   new +OrderDetail+s to, false if we want a brand new order
  def cart(created_by_user = nil, find_existing = true)
    if find_existing
      Cart.new(self, created_by_user).order
    else
      Cart.new(self, created_by_user).new_cart
    end
  end

  def account_price_groups
    accounts.active.collect(&:price_groups).flatten.uniq
  end

  #
  # Given a +Product+ returns all valid accounts this user has for
  # purchasing that product
  def accounts_for_product(product)
    return [NonbillableAccount.singleton_instance] if product.nonbillable_mode?

    acts = accounts.active.for_facility(product.facility).to_a
    acts.reject! { |acct| !acct.validate_against_product(product, self).nil? }
    acts
  end

  # Returns a hash of product_id => approved_at date when this user was granted
  # access to the product
  def approval_dates_by_product
    product_users.pluck(:product_id, :approved_at).to_h
  end

  def administered_order_details
    OrderDetail.where(account_id: Account.administered_by(self))
  end

  def full_name(suspended_label: true)
    Users::NamePresenter.new(self, suspended_label: suspended_label).full_name
  end

  alias to_s full_name
  alias name full_name

  def last_first_name(suspended_label: true)
    Users::NamePresenter.new(self, suspended_label: suspended_label).last_first_name
  end

  # Devise uses this method for determining if a user is allowed to log in. It
  # also gets called on each request, so if a user gets suspended, they'll be
  # kicked out of their session.
  def active_for_authentication?
    super && active?
  end

  def active?
    !suspended? && !expired?
  end

  def suspended?
    suspended_at.present?
  end

  def expired?
    expired_at.present?
  end

  def internal?
    price_groups.include?(PriceGroup.base)
  end

  def update_price_group(params)
    if params[:internal] == "true"
      price_group_members.find_by(price_group: PriceGroup.external).try(:destroy)
      price_group_members.find_or_create_by(price_group: PriceGroup.base)
    elsif params[:internal] == "false"
      price_group_members.find_by(price_group: PriceGroup.base).try(:destroy)
      price_group_members.find_or_create_by(price_group: PriceGroup.external)
    else
      true
    end
  end

  def default_price_group
    self.class.default_price_group_finder.call(self)
  end

  def create_default_price_group!
    return unless SettingsHelper.feature_on?(:user_based_price_groups)

    price_group_members.find_or_create_by!(price_group: default_price_group)
  end

  def lock_access!(opts = { })
    super
    LogEvent.log(self, :access_locked, self, metadata: {cause: "Too many login attempts"})
  end
end
