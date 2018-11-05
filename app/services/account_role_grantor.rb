# frozen_string_literal: true

class AccountRoleGrantor

  attr_reader :account, :by

  def initialize(account, by:)
    @account = account
    @by = by
  end

  def grant(user, role)
    account_user = nil

    within_transaction do
      # Remove the old owner if we're assigning a new one
      remove_old_user if role == AccountUser::ACCOUNT_OWNER

      account_user = find_or_build_user_role(user, role)
      account_user.save!

      # In order to allow changes once an account is closed (i.e. becomes invalid
      # per the Validator) we cannot run the validations directly on the account.
      account.require_owner
      raise ActiveRecord::Rollback if account.errors.any?
    end

    account_user
  end

  private

  def remove_old_user
    # Soft-delete the old owner record
    account.owner&.update!(
      deleted_at: Time.current,
      deleted_by: by.id,
    )
  end

  def find_or_build_user_role(user, role)
    # find non-deleted record for this user and account or init new one
    # deleted_at MUST be nil to preserve existing audit trail
    account_user = AccountUser.find_or_initialize_by(account: account, user: user, deleted_at: nil)
    account_user.assign_attributes(
      user_role: role,
      created_by_user: by,
    )
    account_user
  end

  def within_transaction
    account.transaction do
      yield
    end
  rescue ActiveRecord::RecordInvalid
    # do nothing
  end

end
