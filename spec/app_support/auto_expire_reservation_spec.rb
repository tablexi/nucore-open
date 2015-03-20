require 'spec_helper'

describe AutoExpireReservation, :timecop_freeze do
  let(:now) { DateTime.now.change(hour: 9, min: 31)  }

  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }

  describe '#perform' do
    context 'a new reservation' do
      let!(:reservation) { create(:purchased_reservation, :yesterday, actual_start_at: 1.hour.ago) }

      it 'completes the reservation' do
        expect { action.perform }.to change { order_detail.reload.state }.from('new').to('complete')
      end

      it 'sets this to a problem reservation' do
        expect { action.perform }.to change { order_detail.reload.problem }.to(true)
      end

      it 'does not assign pricing' do
        action.perform
        expect(order_detail.reload.price_policy).to be_nil
      end

      it 'sets the reservation fulfilled at time' do
        expect { action.perform }.to change { order_detail.reload.fulfilled_at }.to(reservation.reserve_end_at)
      end
    end

    context 'an unpurchased reservation' do
      let!(:reservation) { create(:setup_reservation, :yesterday, actual_start_at: 1.hour.ago) }

      before do
        action.perform
        order_detail.reload
        reservation.reload
      end

      include_examples 'it does not complete order' do
        it 'leaves state as new' do
          expect(order_detail.state).to eq('new')
        end

        it 'leaves order status nil' do
          expect(reservation.actual_end_at).to be_nil
        end

        it 'leaves order status nil' do
          expect(order_detail.order_status).to eq(nil)
        end
      end
    end

    context 'a reservation which has not passed the end time' do
      let!(:reservation) do
        start_at = 30.minutes.ago
        end_at = 1.minute.from_now

        create(:purchased_reservation,
            product: create(:setup_instrument, min_reserve_mins: 1),
            actual_start_at: 30.minutes.ago,
            reserve_start_at: start_at,
            reserve_end_at: end_at)
      end

      before do
        action.perform
        order_detail.reload
        reservation.reload
      end

      include_examples 'it does not complete order' do
        it 'leaves state as new' do
          expect(order_detail.state).to eq('new')
        end

        it 'leaves order status nil' do
          expect(reservation.actual_end_at).to be_nil
        end

        it 'leaves order status nil' do
          expect(order_detail.order_status.name).to eq('New')
        end
      end
    end
      end
    end
  end
end
