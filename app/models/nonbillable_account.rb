# frozen_string_literal: true

class NonbillableAccount < Account
  before_validation :set_owner, :set_description, :set_created_by, :set_account_number, :set_expries_at

  def account_open?(_)
    true
  end

  private

  def set_account_number
    return if account_number
    self.account_number = "non-billable-account"
  end

  def set_description
    return if description
    self.description = "Nonbillable Account"
  end

  def set_expries_at
    return if expires_at
    self.expires_at = 75.years.from_now
  end

  def set_created_by
    reutnr if created_by
    self.created_by = User.nonbillable_account_owner.id
  end

  def set_owner
    return if owner

    account_users << AccountUser.new(
      user_role: AccountUser::ACCOUNT_OWNER,
      user: User.nonbillable_account_owner,
      created_by_user: User.nonbillable_account_owner,
    )
  end
end
