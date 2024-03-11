# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reserving an instrument using quick reservations" do
  let(:user) { create(:user) }
  let!(:user_2) { create(:user) }
  let!(:admin_user) { create(:user, :administrator) }
  let!(:instrument) { create(:setup_instrument, :timer, min_reserve_mins: 5) }
  let(:intervals) { instrument.quick_reservation_intervals }
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
      expect(page).to have_content("9:31 AM - 10:01 AM")
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

  context "when the user has an ongoing reservation" do
    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user:,
        reserve_start_at: 30.minutes.ago,
        actual_start_at: 30.minutes.ago,
        reserve_end_at: 1.hour.from_now
      )
    end

    it "can stop the reservation" do
      expect(page).to have_content("9:00 AM - 10:30 AM")
      click_link("End Reservation")
      expect(page).to have_content("The instrument has been deactivated successfully")
    end
  end

  context "when another reservation exists in the future" do
    let(:start_at) {}
    let(:end_at) { start_at + 30.minutes }

    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user: user_2,
        reserve_start_at: start_at,
        reserve_end_at: end_at
      )
    end

    context "when the reservation is outside of all the walkup reservation intervals" do
      let(:start_at) { Time.current + intervals.last.minutes + 5.minutes }

      it "can start a reservation right now" do
        expect(page).to have_content("15 mins")
        expect(page).to have_content("30 mins")
        expect(page).to have_content("60 mins")
        choose "60 mins"
        click_button "Create Reservation"
        expect(page).to have_content("9:31 AM - 10:31 AM")
        expect(page).to have_content("End Reservation")
      end
    end

    context "when the reservation is ouside only 2 of the walkup reservation intervals" do
      let(:start_at) { Time.current + intervals[1].minutes + 5.minutes }

      it "can start a reservation right now" do
        expect(page).to have_content("15 mins")
        expect(page).to have_content("30 mins")
        expect(page).to_not have_content("60 mins")
        choose "30 mins"
        click_button "Create Reservation"
        expect(page).to have_content("9:31 AM - 10:01 AM")
        expect(page).to have_content("End Reservation")
      end
    end

    context "when the reservation is inside all of the walkup reservation intervals" do
      let(:start_at) { Time.current + intervals.first.minutes - 5.minutes }

      it "can create a reservation for later on" do
        expect(page).to have_content("Someone has a reservation comping up. Next available start time is")
        expect(page).to have_content("Reservation Time 10:10 AM")
        expect(page).to have_content("15 mins")
        expect(page).to have_content("30 mins")
        expect(page).to have_content("60 mins")
      end
    end
  end

  context "when another reservation is ongoing but abandoned" do
    let!(:reservation) do
      create(
        :purchased_reservation,
        product: instrument,
        user: user_2,
        reserve_start_at: 30.minutes.ago,
        actual_start_at: 30.minutes.ago,
        reserve_end_at: 15.minutes.ago
      )
    end

    it "can start a reservaton right now, and move the abandoned reservation into the problem queue" do
      choose "30 mins"
      click_button "Create Reservation"
      expect(page).to have_content("9:31 AM - 10:01 AM")
      expect(page).to have_content("End Reservation")
      # test that the abandoned reservation goes into the problem queue
      visit root_path
      click_link "Logout"
      login_as admin_user
      visit show_problems_facility_reservations_path(facility)
      expect(page).to have_content(reservation.order.id)
      expect(page).to have_content("Missing Actuals")
    end
  end

  # locally test: if another reservation exists but has not been started, nothing will happen (the relay stays on).
end
