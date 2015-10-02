require "rails_helper"

RSpec.describe NotificationSender, :aggregate_failures do
  let(:user) { create(:user) }

  let(:facility) { create(:facility) }

  let(:facility_account) do
    facility.facility_accounts.create(attributes_for(:facility_account))
  end

  let(:item) do
    facility
    .items
    .create(attributes_for(:item, facility_account_id: facility_account.id))
  end

  let(:account) { create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => user), :facility_id => facility.id) }
  let(:ids) { order_details.map(&:id) }
  let(:action) { described_class.new(facility, ids) }

  describe "with a reasonable sized group" do
    let!(:order_details) { 5.times.map { place_product_order(user, facility, item, account) } }

    before { OrderDetail.update_all(state: "complete", price_policy_id: item.price_policies.first.id) }

    it "notifies the appropriate accounts and sets the order details to reviewed" do
      expect(action.perform).to be_truthy
      expect(action.account_ids_notified).to eq([account.id])
      expect(order_details).to be_all { |od| od.reload.reviewed_at? }
    end

    describe "with an id that does not exist" do
      let(:ids) { [-1, order_details.first.id] }

      it "has an error for the id" do
        expect(action.perform).to be_falsey
        expect(action.errors.first).to include("-1")
        expect(order_details.first.reload).not_to be_reviewed
      end
    end
  end

  describe "with more than 1000 items" do
    let!(:order_details) do
      1001.times.map do
        place_product_order(user, facility, item, account)
      end
    end

    it "allows notification" do
      OrderDetail.update_all(state: "complete", price_policy_id: item.price_policies.first.id)
      expect(action.perform).to be_truthy
      expect(action.account_ids_notified).to eq([account.id])
    end
  end
end
