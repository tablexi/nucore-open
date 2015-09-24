require "rails_helper"

RSpec.describe OrderDetailsController do
  describe '#dispute' do
    let(:user) { order_detail.user }
    let(:reservation) { create(:purchased_reservation) }
    let(:order_detail) { reservation.order_detail }
    let(:order) { order_detail.order }
    let(:params) { { order_id: order.id, order_detail_id: order_detail.id} }
    before { sign_in user }

    context 'the order is not disputable' do
      it 'returns a 404' do
        put :dispute, params
        expect(response.code).to eq("404")
      end
    end

    context 'it is disputable' do
      before do
        order_detail.update_attributes!(state: 'complete', reviewed_at: 7.days.from_now)
        put :dispute, params.merge(order_detail_params)
      end

      context 'with a blank reason' do
        let(:order_detail_params) { { order_detail: { dispute_reason: '' } } }

        it 'does not dispute' do
          expect(order_detail.reload).not_to be_disputed
        end
      end

      context 'successful dispute' do
        let(:order_detail_params) { { order_detail: { dispute_reason: 'Too expensive' } } }

        it 'disputes' do
          expect(order_detail.reload).to be_disputed
        end

        it 'captures who disputed it' do
          expect(order_detail.reload.dispute_by).to eq(user)
        end
      end
    end
  end
end
