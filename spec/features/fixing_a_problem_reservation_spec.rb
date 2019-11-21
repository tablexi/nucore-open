require "rails_helper"

RSpec.describe "Fixing a problem reservation" do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, :always_available, facility: facility) }

  before { login_as reservation.user }
  describe "a problem reservation" do
    let(:reservation) { create(:completed_reservation, product: instrument, actual_end_at: nil) }

    it "can edit the reservation" do
      skip "not ready yet"
      expect(reservation.order_detail).to be_problem
      visit edit_problem_reservation_path(reservation)

      fill_in :actual_end_at_date, with: "2019-01-01"

    end
  end

  describe "not a problem" do
    let(:reservation) { create(:completed_reservation, product: instrument, reserve_start_at: 2.hours.ago, reserve_end_at: 1.hour.ago) }

    it "cannot view the page" do
      expect(reservation.order_detail).not_to be_problem
      visit edit_problem_reservation_path(reservation)
      expect(page).to have_content("You cannot edit this order")
    end
  end

  describe "a problem because of missing price policy" do
    let(:reservation) { create(:completed_reservation, product: instrument) }

    it "cannot view the page" do
      expect(reservation.order_detail).to be_problem
      visit edit_problem_reservation_path(reservation)
      expect(page).to have_content("You cannot edit this order")
    end
  end
end
