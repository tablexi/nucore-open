# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing mode workflows" do
  let(:facility) { create(:setup_facility, accepts_po:) }
  let(:accepts_po) { true }
  let(:billing_mode) { "Default" }
  let(:item) { create(:setup_item, facility:, billing_mode:) }
  let(:order) { create(:setup_order, product: item, account: create(:purchase_order_account, :with_account_owner)) }
  let(:order_detail) { order.order_details.first }
  let(:nufs_account) { order.account }
  let(:logged_in_user) { create(:user, :facility_director, facility:) }

  before do
    login_as logged_in_user
  end

  describe "'Default' billing mode"

  describe "'Skip Review' billing mdoe" do
    let(:billing_mode) { "Skip Review" }

    context "valid account" do
      it "automatically moves an order detail from complete to reconciled", :js do
        order._validate_order!
        order.purchase!
        visit manage_facility_order_order_detail_path(facility, order, order_detail)

        select "Complete", from: "Order Status"

        click_button "Save"
        visit facility_transactions_path(facility)

        expect(page).to have_selector("tr td.nowrap", text: "Reconciled")
      end
    end

    context "invalid account" do
      let(:accepts_po) { false }

      it "should not have a valid cart" do
        expect(order.cart_valid?).to be false
      end
    end
  end

  describe "'Nonbillable' billing mode"
end
