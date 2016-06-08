require "rails_helper"

RSpec.describe "Purchasing a reservation" do

  let!(:instrument) { FactoryGirl.create(:setup_instrument) }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryGirl.create(:instrument_price_policy, price_group: PriceGroup.base.first, product: instrument) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:account_price_group_member) do
    FactoryGirl.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  before do
    login_as user
    visit root_path
    click_link facility.name
    click_link instrument.name
    select user.accounts.first.description, from: "Payment Source"
    click_button "Create"
  end

  it "is on the My Reservations page" do
    expect(page).to have_content "My Reservations"
  end
end
