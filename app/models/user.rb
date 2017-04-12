class User < ActiveRecord::Base

  # module Overridable

  #   #
  #   def price_groups
  #     groups = price_group_members.collect(&:price_group)
  #     # check internal/external membership
  #     groups << (username =~ /@/ ? PriceGroup.external : PriceGroup.base)
  #     groups.flatten.uniq
  #   end

  # end

  include ::Users::Roles
  include NUCore::Database::WhereIdsIn

  # ldap_authenticatable is included via a to_prepare hook if ldap is enabled
  devise :database_authenticatable, :encryptable, :trackable, :recoverable

  has_many :accounts, through: :account_users
  has_many :account_users, -> { where(deleted_at: nil) }
  has_many :orders
  has_many :order_details, through: :orders
  has_many :price_group_members
  has_many :price_groups, -> { uniq }, through: :price_group_members
  has_many :product_users
  has_many :notifications
  has_many :products, through: :product_users
  has_many :assigned_order_details, class_name: "OrderDetail", foreign_key: "assigned_user_id"
  has_many :user_roles, dependent: :destroy
  has_many :facilities, through: :user_roles
  has_many :training_requests, dependent: :destroy
  has_many :stored_files, through: :order_details, class_name: "StoredFile"
  validates_presence_of :username, :first_name, :last_name
  validates :email, presence: true, email_format: true
  validates_uniqueness_of :username, :email

  #
  # Gem ldap_authenticatable expects User to respond_to? :login. For us that's #username.
  alias_attribute :login, :username

  #
  # Gem ldap_authenticatable expects User to respond_to? :ldap_attributes. For us should return nil.
  attr_accessor :ldap_attributes

  # Scopes

  def self.with_global_roles
    where(id: UserRole.global.select("distinct user_id"))
  end

  def self.with_recent_orders(facility)
    distinct
      .joins(:orders)
      .merge(Order.recent.for_facility(facility))
  end

  def self.sort_last_first
    order("LOWER(users.last_name), LOWER(users.first_name)")
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

  #
  # Returns true if this user is external to organization, false othewise
  def external?
    username.casecmp(email.downcase).zero?
  end

  def internal?
    !external?
  end

  def admin_editable?
    external?
  end

  def password_updatable?
    external?
  end

  def update_password_confirm_current(params)
    unless valid_password? params[:current_password]
      errors.add(:current_password, :incorrect)
    end
    update_password(params)
  end

  def update_password(params)
    unless password_updatable?
      errors.add(:base, :password_not_updatable)
      return false
    end

    errors.add(:password, :empty) if params[:password].blank?
    errors.add(:password, :password_too_short) if params[:password] && params[:password].strip.length < 6
    errors.add(:password_confirmation, :confirmation) if params[:password] != params[:password_confirmation]

    if errors.empty?
      self.password = params[:password].strip
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
    groups = accounts.active.collect(&:price_groups).flatten.uniq
  end

  #
  # Given a +Product+ returns all valid accounts this user has for
  # purchasing that product
  def accounts_for_product(product)
    acts = accounts.active.for_facility(product.facility).to_a
    acts.reject! { |acct| !acct.validate_against_product(product, self).nil? }
    acts
  end

  def administered_order_details
    OrderDetail.where(account_id: Account.administered_by(self))
  end

  def full_name
    if first_name.nil? && last_name.nil?
      username
    else
      full = ""
      full += first_name unless first_name.nil?
      full += " " unless first_name.nil? || last_name.nil?
      full += last_name unless last_name.nil?
      full
    end
  end

  def last_first_name
    "#{last_name}, #{first_name}" + deactivated_string
  end

  def to_s
    full_name + deactivated_string
  end
  alias name to_s

  def deactivated_string
    if active?
      ""
    else
      " (#{self.class.human_attribute_name(:deactivated)})"
    end
  end

  def recently_used_facilities(limit = 5)
    @recently_used_facilities ||= Hash.new do |hash, key|
      facility_ids = orders.purchased.order("MAX(ordered_at) DESC").limit(limit).group(:facility_id).pluck(:facility_id)
      hash[key] = Facility.where(id: facility_ids).sorted
    end
    @recently_used_facilities[limit]
  end

  # Devise uses this method for determining if a user is allowed to log in. It
  # also gets called on each request, so if a user gets deactivated, they'll be
  # kicked out of their session.
  def active_for_authentication?
    super && active?
  end

  def deactivate
    update_attribute(:deactivated_at, deactivated_at || Time.current)
  end

  def activate
    update_attribute(:deactivated_at, nil)
  end

  def active?
    deactivated_at.blank?
  end

  def self.active
    where(deactivated_at: nil)
  end

end
