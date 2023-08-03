# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing mode workflows" do
  let(:facility) { create(:setup_facility) }
  let(:billing_mode) { "Default" }
  let!(:account) { create(:setup_account, :with_account_owner, facility: order_detail.facility, owner: order_detail.user) }
  let(:instrument) { create(:setup_instrument, facility:, billing_mode:) }
  let(:item) { create(:setup_item, facility:, billing_mode:) }
  let(:now) { Time.now }
  let(:reservation) { create(:purchased_reservation, product: instrument, reserve_start_at: 1.hour.ago, reserve_end_at: now, actual_start_at: 1.hour.ago, actual_end_at: now) }
  # let(:order_detail) { reservation.order_detail }
  let(:order) { create(:setup_order, product: item) }
  let(:order_detail) { order.order_details.first }
  let(:administrator) { create(:user, :administrator) }
  let(:director) { create(:user, :facility_director, facility:) }
  let(:logged_in_user) { director }

  before do
    order._validate_order!
    order.purchase!
    login_as logged_in_user
    visit manage_facility_order_order_detail_path(facility, order, order_detail)
  end

  context "'Default' billing mode"

  context "'Skip Review' billing mdoe" do
    let(:billing_mode) { "Skip Review" }

    it "is reconciled when complete" do
      select "Complete", from: "Order Status"
      click_button "Save"
      expect(order_detail.reload.reconciled?).to be true
    end
  end

  context "'Nonbillable' billing mode"
end
