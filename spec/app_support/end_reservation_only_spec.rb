require 'spec_helper'

describe EndReservationOnly, :timecop_freeze do
  let(:now) { DateTime.now.change(hour: 9, min: 31)  }

  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }

  describe '#perform' do
    context 'an unpurchased reservation' do
      let!(:reservation) { create(:setup_reservation, :yesterday) }

      it 'does not do anything' do
        expect { action.perform }.not_to change { reservation.reload.actual_end_at }
        expect(order_detail.state).to eq('new')
        expect(order_detail.order_status_id).to be_blank
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

      it 'completes reservation' do
        expect { action.perform }.to change { order_detail.reload.state }.from('new').to('complete')
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

      it 'does not do anything' do
        expect { action.perform }.not_to change { reservation.reload.actual_end_at }
        expect(order_detail.state).to eq('new')
        expect(order_detail.order_status_id).to be_blank
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

      it 'does not do anything' do
        expect { action.perform }.not_to change { reservation.reload.actual_end_at }
        expect(order_detail.state).to eq('new')
      end
    end
  end
end
