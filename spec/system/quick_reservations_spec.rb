# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reserving an instrument using quick reservations" do
  let(:user) { create(:user) }
  let!(:instrument) { create(:setup_instrument, min_reserve_mins: 5) }
  let(:facility) { instrument.facility }
  let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let!(:reservation) {}

  before do
    login_as user
    visit facility_instrument_quick_reservations_path(facility, instrument)
  end

  context "when there is no current reservation" do
    it "can start a reservation right now" do
      choose "30 mins"
      click_button "Create Reservation"
      expect(page).to have_content("9:30 AM - 10:00 AM")
      expect(page).to have_content("End Reservation")
    end
  end

  context "when the user has a future reservation" do
    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user:,
        reserve_start_at: 1.hour.from_now,
        reserve_end_at: 1.hour.from_now + 30.minutes
      )
    end

    it "can move up and start their reservation" do
      click_button "start reservation"
      expect(page).to have_content("9:31 AM - 10:01 AM")
      expect(page).to have_content("End Reservation")
    end
  end

  context "when the user has an ongoing reservation"
end
