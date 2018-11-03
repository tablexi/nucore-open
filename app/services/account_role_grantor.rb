class AccountRoleGrantor

  attr_reader :account, :by

  def initialize(account, by:)
    @account = account
    @by = by
  end

  def grant(user, role)
    account_user = nil

    within_transaction do
        # expire old owner if it's a new user
      remove_old_user if role == AccountUser::ACCOUNT_OWNER

      account_user = create_or_update_user_role(user, role)

      unless account.reload.owner.present?
        account_user.errors.add(:base, "Must have an account owner")
        raise ActiveRecord::Rollback
      end
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

  def create_or_update_user_role(user, role)
    # find non-deleted record for this user and account or init new one
    # deleted_at MUST be nil to preserve existing audit trail
    account_user = AccountUser.find_or_initialize_by(account: account, user: user, deleted_at: nil)
    account_user.update!(
      user_role: role,
      created_by_user: by
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
