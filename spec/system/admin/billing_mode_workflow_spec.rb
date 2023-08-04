# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Billing mode workflows" do
  let(:facility) { create(:setup_facility, accepts_po:) }
  let(:accepts_po) { true }
  let(:billing_mode) { "Default" }
  let(:item) { create(:setup_item, facility:, billing_mode:) }
  let(:order) { create(:setup_order, product: item) }
  let(:order_detail) { order.order_details.first }
  let(:nufs_account) { order.account }
  let(:account) { nufs_account }
  let(:logged_in_user) { create(:user, :facility_director, facility:) }

  let(:po_account) do
    po = create(:purchase_order_account, account_users: nufs_account.account_users)
    create(:account_price_group_member, account: po, price_group: item.price_groups.last)
    po
  end

  before do
    order.account = account
    order_detail.account_id = order.account_id # needed for cart validation
    login_as logged_in_user
  end

  describe "'Default' billing mode"

  describe "'Skip Review' billing mdoe" do
    let(:billing_mode) { "Skip Review" }

    context "valid account" do
      it "is reconciled when complete" do
        order._validate_order!
        order.purchase!
        visit manage_facility_order_order_detail_path(facility, order, order_detail)

        select "Complete", from: "Order Status"
        click_button "Save"
        expect(order_detail.reload.reconciled?).to be true
      end
    end

    context "invalid account" do
      let(:accepts_po) { false }
      let(:account) { po_account }

      it "should not have a valid cart" do
        expect(order.cart_valid?).to be false
      end
    end
  end

  describe "'Nonbillable' billing mode"
end
