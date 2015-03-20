require 'spec_helper'

describe EndReservationOnly, :timecop_freeze do
  let(:now) { DateTime.now.change(hour: 9, min: 31)  }

  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }

  describe '#perform' do
    context 'an unpurchased reservation' do
      let!(:reservation) { create(:setup_reservation, :yesterday) }

      before { action.perform }

      include_examples 'it does not complete order' do
        it 'leaves state as new' do
          expect(order_detail.state).to eq('new')
        end

        it 'leaves order status nil' do
          expect(order_detail.reload.order_status_id).to be_nil
        end
      end
    end

    context 'a new reservation only instrument' do
      let!(:reservation) do
        start_at = 30.minutes.ago
        end_at = 1.minute.ago

        create(:purchased_reservation,
            product: create(:setup_instrument, min_reserve_mins: 1),
            reserve_start_at: start_at,
            reserve_end_at: end_at)
      end

      before do
        expect(order_detail.reload.state).to eq('new')
        action.perform
      end

      it 'completes reservation' do
        expect(order_detail.reload.state).to eq('complete')
      end

      it 'sets fulfilled at to end reservation time' do
        expect(order_detail.reload.fulfilled_at).to eq(reservation.reserve_end_at)
      end

      it 'sets price policy' do
        expect(order_detail.reload.price_policy).to_not be_nil
      end

      it 'is not a problem reservation' do
        expect(order_detail.reload).to_not be_problem
      end
    end

    context 'an unpurchased reservation only instrument' do
      let!(:reservation) do
        start_at = 30.minutes.ago
        end_at = 1.minute.ago

        create(:setup_reservation,
            product: create(:setup_instrument, min_reserve_mins: 1),
            reserve_start_at: start_at,
            reserve_end_at: end_at)
      end

      before { action.perform }

      include_examples 'it does not complete order' do
        it 'leaves state as new' do
          expect(order_detail.state).to eq('new')
        end

        it 'leaves order status nil' do
          expect(order_detail.reload.order_status_id).to be_nil
        end
      end
    end

    context 'a reservation which has not passed the end time' do
      let!(:reservation) do
        start_at = 30.minutes.ago
        end_at = 1.minute.from_now

        create(:purchased_reservation,
            product: create(:setup_instrument, min_reserve_mins: 1),
            reserve_start_at: start_at,
            reserve_end_at: end_at)
      end

      before { action.perform }

      include_examples 'it does not complete order' do
        it 'leaves state as new' do
          expect(order_detail.state).to eq('new')
        end

        it 'leaves order status nil' do
          expect(order_detail.reload.order_status.name).to eq('New')
        end
      end
    end
  end
end
