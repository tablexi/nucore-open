require "rails_helper"

RSpec.describe "Cloning account membership" do
  let(:facility) { create(:facility) }
  let(:admin) { create(:user, :administrator) }
  let(:original_user) { create(:user) }
  let(:new_user) { create(:user) }
  let(:owned_account) { create(:account, :with_account_owner, owner: original_user) }
  let(:business_admin_account) { create(:account, :with_account_owner) }
  let(:purchaser_account) { create(:account, :with_account_owner) }
  let(:purchaser_account_to_not_clone) { create(:account, :with_account_owner) }

  before do
    create(:account_user, :business_administrator, user: original_user, account: business_admin_account)
    create(:account_user, :purchaser, user: original_user, account: purchaser_account)
    create(:account_user, :purchaser, user: original_user, account: purchaser_account_to_not_clone)

    login_as admin
  end

  it "can clone the account roles to the new user" do
    visit facility_user_accounts_path(facility, new_user)

    click_link "Clone Payment Source Membership"
    fill_in "User", with: original_user.name

    click_link original_user.name

    check owned_account.to_s
    check business_admin_account.to_s
    check purchaser_account.to_s

    click_button "Clone"

  end
end
