require "rails_helper"

RSpec.describe OrderDetailsController do
  let(:order) { order_detail.order }
  let(:order_detail) { reservation.order_detail }
  let(:reservation) { create(:purchased_reservation) }

  describe "#dispute" do
    let(:params) { { order_id: order.id, order_detail_id: order_detail.id } }
    let(:user) { order_detail.user }
    before { sign_in user }

    context "when the order is not disputable" do
      before { put :dispute, params }

      it { expect(response.code).to eq("404") }
    end

    context "when the order is disputable" do
      before(:each) do
        order_detail.update_attributes!(state: "complete", reviewed_at: 7.days.from_now)
        put :dispute, params.merge(order_detail: { dispute_reason: dispute_reason })
      end

      context "with a blank dispute_reason" do
        let(:dispute_reason) { "" }

        it { expect(order_detail.reload).not_to be_disputed }
      end

      context "with a dispute_reason" do
        let(:dispute_reason) { "Too expensive" }

        it { expect(order_detail.reload).to be_disputed }

        it "captures who disputed it" do
          expect(order_detail.reload.dispute_by).to eq(user)
        end
      end
    end
  end

  describe "#show" do
    before(:each) do
      sign_in user
      get :show, order_id: order.id, order_detail_id: order_detail.id
    end

    context "when logged in as the user who owns the order" do
      let(:user) { order_detail.user }

      it { expect(response.code).to eq("200") }
    end

    context "when logged in as a user that does not own the order" do
      let(:user) { create(:user) }

      it { expect(response.code).to eq("404") }
    end
  end
end
