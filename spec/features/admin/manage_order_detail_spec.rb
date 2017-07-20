require "rails_helper"

RSpec.describe "Managing an order detail" do

  let(:facility) { create(:setup_facility) }
  let(:instrument) { FactoryGirl.create(:setup_instrument, facility: facility, control_mechanism: "timer") }
  let(:reservation) { create(:purchased_reservation, product: instrument) }
  let(:order_detail) { reservation.order_detail }
  let(:order) { reservation.order }

  let(:director) { create(:user, :facility_director, facility: facility) }


  before do
    login_as director
    visit manage_facility_order_order_detail_path(facility, order, order_detail)
  end

  describe "editing an order detail with a reservation" do
    it "can change the note" do
      fill_in "Note", with: "hello"
      click_button "Save"
      expect(order_detail.reload.note).to eq "hello"
      expect(page).to have_content("successfully updated")
    end

    it "can change reservation duration" do
      fill_in "Duration", with: "90"
      click_button "Save"
      new_end_at = order_detail.reservation.reload.reserve_start_at + 90.minutes

      expect(order_detail.reservation.reload.reserve_end_at).to eq(new_end_at)
      expect(page).to have_content("successfully updated")
    end
  end
end
