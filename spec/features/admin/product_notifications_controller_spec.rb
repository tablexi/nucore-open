require "rails_helper"

RSpec.describe ProductNotificationsController do
  let(:facility) { create(:setup_facility) }
  let!(:instrument) { create(:instrument, facility: facility) }

  describe "as a facility director" do
    before { login_as create(:user, :facility_director, facility: facility) }

    it "can update the fields" do
      visit facility_instruments_path(facility)
      click_link instrument.name
      click_link "Notifications"
      click_link "Edit"

      fill_in "Order Notification Recipient", with: "user1@example.com"
      fill_in "Cancellation Notification Contacts", with: "user2@example.com, user3@example.com"
      click_button "Save"

      expect(page).to have_content("Order Notification Recipient\nuser1@example.com")
      expect(page).to have_content("Cancellation Notification Contacts\nuser2@example.com, user3@example.com")
    end
  end

  describe "as facility senior staff" do
    before { login_as create(:user, :senior_staff, facility: facility) }

    it "does not see the edit button" do
      visit facility_instruments_path(facility)
      click_link instrument.name
      click_link "Notifications"
      expect(page).not_to have_link("Edit")
    end

    it "cannot access the edit view" do
      visit facility_product_edit_notifications_path(facility, instrument)
      expect(page).to have_content("Permission Denied")
    end
  end
end
