class User < ActiveRecord::Base

  module Overridable
    def price_groups
      groups = price_group_members.collect{ |pgm| pgm.price_group }
      # check internal/external membership
      groups << (self.username.match(/@/) ? PriceGroup.external.first : PriceGroup.base.first)
      groups.flatten.uniq
    end
  end

  include Overridable
  include Role

  # ldap_authenticatable is included via a to_prepare hook if ldap is enabled
  devise :database_authenticatable, :encryptable, :trackable, :recoverable

  has_many :accounts, :through => :account_users
  has_many :account_users, :conditions => {:deleted_at => nil}
  has_many :orders
  has_many :order_details, :through => :orders
  has_many :price_group_members
  has_many :product_users
  has_many :notifications
  has_many :products, :through => :product_users
  has_many :assigned_order_details, :class_name => 'OrderDetail', :foreign_key => 'assigned_user_id'
  has_many :user_roles, :dependent => :destroy
  has_many :facilities, :through => :user_roles

  validates_presence_of :username, :first_name, :last_name
  validates_format_of :email, :with => /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,6}$/i
  validates_uniqueness_of :username, :email

  #
  # Gem ldap_authenticatable expects User to respond_to? :login. For us that's #username.
  alias_attribute :login, :username

  #
  # Gem ldap_authenticatable expects User to respond_to? :ldap_attributes. For us should return nil.
  attr_accessor :ldap_attributes


  # finds all user role mappings for a this user in a facility
  def facility_user_roles(facility)
    UserRole.find_all_by_facility_id_and_user_id(facility.id, id)
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
    username == email
  end

  def password_updatable?
    external?
  end

  def update_password_confirm_current(params)
    unless self.valid_password? params[:current_password]
      self.errors.add(:current_password, :incorrect)
    end
    update_password(params)
  end
  def update_password(params)
    unless password_updatable?
      self.errors.add(:base, :password_not_updatable)
      return false
    end

    self.errors.add(:password, :empty) if params[:password].blank?
    self.errors.add(:password, :password_too_short) if params[:password] and params[:password].strip.length < 6
    self.errors.add(:password_confirmation, :confirmation) if params[:password] != params[:password_confirmation]

    if self.errors.empty?
      self.password = params[:password].strip
      self.clear_reset_password_token
      self.save!
      return true
    else
      return false
    end


  end
  # Find the users for a facility
  # TODO: move this to facility?
  def self.find_users_by_facility(facility)
    find_by_sql(<<-SQL)
      SELECT u.*
      FROM #{User.table_name} u
      LEFT JOIN #{UserRole.table_name} ur ON u.id=ur.user_id
      WHERE ur.facility_id = #{facility.id}
      ORDER BY LOWER(ur.role), LOWER(u.last_name), LOWER(u.first_name)
    SQL
  end

  #
  # A cart is an order. This method finds this user's order.
  # [_created_by_user_]
  #   The user that created the order we want. +self+ is
  #   inferred if left nil.
  # [_find_existing_]
  #   true if we want to look in the DB for an order to add
  #   new +OrderDetail+s to, false if we want a brand new order
  def cart(created_by_user = nil, find_existing=true)
    if find_existing
      Cart.new(self, created_by_user).order
    else
      Cart.new(self, created_by_user).new_cart
    end
  end

  def account_price_groups
    groups = self.accounts.active.collect{ |a| a.price_groups }.flatten.uniq
  end


  #
  # Given a +Product+ returns all valid accounts this user has for
  # purchasing that product
  def accounts_for_product(product)
    acts=accounts.active.for_facility(product.facility)
    acts.reject!{|acct| !acct.validate_against_product(product, self).nil?}
    acts
  end


  def full_name
    unless first_name.nil? and last_name.nil?
      full = ""
      full += first_name unless first_name.nil?
      full += " " unless first_name.nil? || last_name.nil?
      full += last_name unless last_name.nil?
      full
    else
      username
    end
  end

  def to_s
    full_name
  end
end
