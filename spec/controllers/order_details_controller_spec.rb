require "rails_helper"

RSpec.describe OrderDetailsController do
  describe "#dispute" do
    let(:user) { order_detail.user }
    let(:reservation) { create(:purchased_reservation) }
    let(:order_detail) { reservation.order_detail }
    let(:order) { order_detail.order }
    let(:params) { { order_id: order.id, order_detail_id: order_detail.id } }
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
end
