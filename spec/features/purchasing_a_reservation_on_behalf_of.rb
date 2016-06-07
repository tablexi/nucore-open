require "rails_helper"

RSpec.describe "Purchasing a reservation on behalf of another user" do
  fixtures :all

  let(:facility) { facilities(:facility) }
  let(:instrument) { products(:reservation_only_instrument) }
  let(:facility_admin) { users(:facility_admin) }
  let(:user) { users(:normal_user) }

  before do
    login_as facility_admin
    visit facility_users_path(facility)
    fill_in "search_term", with: user.first_name
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
