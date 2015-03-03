require 'spec_helper'

describe AutoExpire do
  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }

  describe '#perform' do
    context 'a new reservation' do
      let!(:reservation) { create(:purchased_reservation, :yesterday) }

      it 'completes the reservation' do
        expect { action.perform }.to change { order_detail.reload.state }.from('new').to('complete')
      end
    end

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
        start_at = Time.zone.parse("#{Date.today} 9:00:00")
        end_at = start_at + 30.minutes

        create(:purchased_reservation,
            product: create(:setup_instrument, :reservation_only, min_reserve_mins: 30),
            reserve_start_at: start_at,
            reserve_end_at: end_at)
      end


      it 'completes reservation' do
        expect { action.perform }.to change { order_detail.reload.state }.from('new').to('complete')
      end
    end

    context 'an unpurchased reservation only instrument' do
      let!(:reservation) do
        start_at = Time.zone.parse("#{Date.today} 9:00:00")
        end_at = start_at + 30.minutes

        create(:setup_reservation,
            product: create(:setup_instrument, :reservation_only, min_reserve_mins: 30),
            reserve_start_at: start_at,
            reserve_end_at: end_at)
      end

      it 'does not do anything' do
        expect { action.perform }.not_to change { reservation.reload.actual_end_at }
        expect(order_detail.state).to eq('new')
        expect(order_detail.order_status_id).to be_blank
      end
    end
  end
end
