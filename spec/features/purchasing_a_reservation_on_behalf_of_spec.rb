require "rails_helper"

RSpec.describe "Purchasing a reservation on behalf of another user" do

  let!(:instrument) { FactoryGirl.create(:setup_instrument) }
  let!(:facility) { instrument.facility }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryGirl.create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let(:user) { FactoryGirl.create(:user) }
  let(:facility_admin) { FactoryGirl.create(:user, :facility_administrator, facility: facility) }
  let!(:account_price_group_member) do
    FactoryGirl.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  before do
    login_as facility_admin
    visit facility_users_path(facility)
    fill_in "search_term", with: user.email
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
      expect(page).to have_content "Order Receipt"
      expect(Reservation.last.note).to eq("A note")
    end
  end

  describe "ordering over an administrative hold" do
    let!(:admin_reservation) { create(:admin_reservation, product: instrument, reserve_start_at: 30.minutes.from_now, duration: 1.hour) }

    describe "when you create a reservation" do
      it "can purchase" do
        click_link instrument.name

        # time is frozen to 9:30am, we expect the default time to be the end of the admin reservation
        expect(page.find_field("reservation_reserve_start_date").value).to match(%r[09/11/\d{4}])
        expect(page.find_field("reservation_reserve_start_hour").value).to eq "11"
        expect(page.find_field("reservation_reserve_start_min").value).to eq "0"
        expect(page.find_field("reservation_reserve_start_meridian").value).to eq "AM"

        fill_in "Duration", with: 90
        select 10, from: "reservation_reserve_start_hour"
        select user.accounts.first.description, from: "Payment Source"
        click_button "Create"

        expect(page).to have_content "Order Receipt"
        # save_and_open_page
        expect(page).to have_content "Warning: You have scheduled over an administrative hold."
        expect(page).to have_content "10:00 AM - 11:30 AM"
      end
    end

  end
end
