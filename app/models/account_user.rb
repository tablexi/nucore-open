# frozen_string_literal: true

class AccountUser < ApplicationRecord

  belongs_to :user, required: true
  belongs_to :account, inverse_of: :account_users, required: true
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by
  has_many :log_events, as: :loggable

  validates :created_by, presence: true
  validates :user_role, inclusion: { in: ->(record) { record.class.user_roles }, message: "is invalid" }
  validates :user_id, uniqueness: { scope: [:account_id, :deleted_at] }, unless: :deleted_at?
  validates :user_role, uniqueness: { scope: [:account_id, :deleted_at] }, if: -> { owner? && !deleted_at? }
  validate :validate_account_has_owner

  ACCOUNT_PURCHASER = "Purchaser"
  ACCOUNT_OWNER = "Owner"
  ACCOUNT_ADMINISTRATOR = "Business Administrator"

  def self.read_only_user_roles
    [ACCOUNT_PURCHASER]
  end

  def self.admin_user_roles
    [ACCOUNT_OWNER, ACCOUNT_ADMINISTRATOR]
  end

  def self.administrators
    User.where(id: where(user_role: admin_user_roles).select(:user_id))
  end

  def self.user_roles
    admin_user_roles + read_only_user_roles
  end

  def self.owners
    where(user_role: ACCOUNT_OWNER)
  end

  def self.business_administrators
    where(user_role: ACCOUNT_ADMINISTRATOR)
  end

  def self.purchasers
    where(user_role: ACCOUNT_PURCHASER)
  end

  def self.active
    where(deleted_at: nil)
  end

  #
  # Provides an +Array+ of roles that can be assigned
  # to a user. Optionally filters the set by the given
  # arguments
  # [_granting_user_]
  # The user selecting a role to be applied to
  # another user; the grantor
  # [_facility_]
  # The facility under which the selected role is
  # granted by +user+
  def self.selectable_user_roles(granting_user = nil, facility = nil)
    case
    when granting_user.blank? || facility.blank?
      user_roles - [ACCOUNT_OWNER]
    when granting_user.account_manager? || granting_user.manager_of?(facility)
      user_roles
    else
      user_roles - [ACCOUNT_OWNER]
    end
  end

  #
  # Assigns +role+ to +user+ for +account+
  # [_user_]
  #   the user you want to grant permissions to
  # [_role_]
  #   one of this class' constants
  # [_account_]
  #   the account that you want to grant permissions on.
  # [_by_]
  #   the user who is granting the privilege
  def self.grant(user, role, account, by:)
    AccountRoleGrantor.new(account, by: by).grant(user, role)
  end

  def can_administer?
    deleted_at.nil? && AccountUser.admin_user_roles.any? { |r| r == user_role }
  end

  def owner?
    user_role == ACCOUNT_OWNER
  end

  def active?
    deleted_at.blank?
  end

  def validate_account_has_owner
    errors.add(:base, :account_missing_owner) if account&.missing_owner?
  end

end
