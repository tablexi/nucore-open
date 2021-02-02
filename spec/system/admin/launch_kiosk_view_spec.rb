# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Launching Kiosk View" do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }

  context "with active reservations" do
    let(:instrument) { create(:setup_instrument, facility: facility, control_mechanism: "timer") }
    let!(:reservation) { create(:purchased_reservation, :running, product: instrument) }

    it "can launch the Kiosk View" do
      login_as director
      visit timeline_facility_reservations_path(facility)
      click_link "Launch Kiosk View"

      expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
      # user should be logged out
      expect(page).to have_content("Login")
    end
  end

  context "with no active reservations" do
    it "cannot launch the Kiosk View" do
      login_as director
      visit timeline_facility_reservations_path(facility)
      expect(page).not_to have_content("Launch Kiosk View")
    end
  end
end
