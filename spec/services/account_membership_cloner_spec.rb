require "rails_helper"

RSpec.describe AccountMembershipCloner, type: :service do
  let(:facility) { create(:facility) }
  let(:admin) { create(:user, :administrator) }
  let(:original_user) { create(:user) }
  let(:new_user) { create(:user) }
  let!(:owned_account) { create(:account, :with_account_owner, owner: original_user) }
  let(:business_admin_account) { create(:account, :with_account_owner) }
  let(:purchaser_account) { create(:account, :with_account_owner) }
  let(:purchaser_account_to_not_clone) { create(:account, :with_account_owner) }

  let(:cloner) {
    described_class.new(
      account_users_to_clone: account_users_to_clone,
      clone_to_user: new_user
    )
  }

  before do
    create(:account_user, :business_administrator, user: original_user, account: business_admin_account)
    create(:account_user, :purchaser, user: original_user, account: purchaser_account)
    create(:account_user, :purchaser, user: new_user, account: purchaser_account_to_not_clone)
  end

  describe "when #perform is called" do
    let(:account_users_to_clone) { AccountUser.where(user: original_user, account: business_admin_account) }

    it "clones the AccountUser objects for one user to a new one" do
      expect { cloner.perform }.to change(AccountUser, :count).by(1)
    end

    it "saves the cloned AccountUser with the appropriate attributes" do
      attributes_to_ignore = ["id", "user_id", "created_at"]

      cloner.perform
      cloned_account_user_attributes = AccountUser.last.attributes.except(*attributes_to_ignore)
      original_account_user_attributes = account_users_to_clone.first.attributes.except(*attributes_to_ignore)

      expect(cloned_account_user_attributes).to match(original_account_user_attributes)
    end
  end

  describe "when invoked to clone an owned account" do
    let(:account_users_to_clone) { AccountUser.where(user: original_user, user_role: "owner") }

    it "assigns the cloned user the accepted alternate role" do
      cloner.perform
      account_user = AccountUser.last

      expect(account_user.user_role).to eq(AccountMembershipCloner::ALT_FOR_PROTECTED_ROLE)
    end
  end

  describe "when attempting to clone an AccountUser where the new user already has an association" do
    let(:account_users_to_clone) { AccountUser.where(user: original_user, account: business_admin_account) }

    before do
      create(:account_user, :business_administrator, user: new_user, account: business_admin_account)
    end

    it "does not create a new AccountUser" do
      expect { cloner.perform }.to_not change(AccountUser, :count)
    end
  end

end
