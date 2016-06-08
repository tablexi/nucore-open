require "rails_helper"

RSpec.describe "Purchasing a reservation on behalf of another user" do

  let!(:instrument) { FactoryGirl.create(:setup_instrument) }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryGirl.create(:instrument_price_policy, price_group: PriceGroup.base.first, product: instrument) }
  let(:user) { FactoryGirl.create(:user) }
  let(:facility_admin) { FactoryGirl.create(:user, :facility_administrator, facility: facility) }

  before do
    login_as facility_admin
    visit facility_users_path(facility)
    fill_in "search_term", with: user.full_name
    click_button "Search"
    click_link "Order For"
  end

  it "is now on the facility page" do
    expect(current_path).to eq(facility_path(facility))
    expect(page).to have_content("You are ordering for #{user.full_name}")
  end

  describe "and you create a reservation" do
    before do
      click_link instrument.name
      select user.accounts.first.description, from: "Payment Source"
      fill_in "Note", with: "A note"
      click_button "Create"
    end

    it "returns to My Reservations" do
      expect(page).to have_content "My Reservations"
      expect(Reservation.last.note).to eq("A note")
    end
  end
end
