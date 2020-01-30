class AccountMembershipCloner

  PROTECTED_USER_ROLE = "Owner".freeze
  ALT_FOR_PROTECTED_ROLE = "Business Administrator".freeze

  attr_reader :error

  def initialize(account_users_to_clone:, clone_to_user:)
    @account_users_to_clone = account_users_to_clone
    @clone_to_user = clone_to_user
  end

  def perform
    perform!
  rescue => e
    @error = e
    false
  end

  private

  def perform!
    ActiveRecord::Base.transaction do
      @account_users_to_clone.each do |au|
        create_account_user(au.attributes)
      end
    end
  end

  def create_account_user(attributes)
    AccountUser.create!(
      user_id: @clone_to_user.id,
      account_id: attributes["account_id"],
      created_by: attributes["created_by"],
      user_role: assign_user_role(attributes["user_role"])
    )
  end

  def assign_user_role(role)
    role == PROTECTED_USER_ROLE ? ALT_FOR_PROTECTED_ROLE : role
  end

end
