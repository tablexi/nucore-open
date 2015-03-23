require 'spec_helper'

describe AutoLogout, :timecop_freeze do
  let(:now) { DateTime.now.change(hour: 9, min: 31)  }

  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }
  let(:relay) { build_stubbed(:relay, auto_logout: true, auto_logout_minutes: 10) }
  before { allow_any_instance_of(Instrument).to receive(:relay).and_return relay }

  describe 'a started reservation past log out time' do
    let!(:reservation) { create(:purchased_reservation, :yesterday, actual_start_at: 1.hour.ago) }

    it 'completes the reservation' do
      expect { action.perform }.to change { order_detail.reload.state }.from('new').to('complete')
    end

    it 'sets the reservation actual end at' do
      expect { action.perform }.to change { reservation.reload.actual_end_at }
    end
  end

  describe 'a new reservation prior to log out time' do
    let!(:reservation) do
      start_at = 30.minutes.ago # 9:01am
      end_at = 1.minute.ago    # 9:30am

      create(:purchased_reservation,
          product: create(:setup_instrument, min_reserve_mins: 1),
          actual_start_at: 30.minutes.ago,
          reserve_start_at: start_at,
          reserve_end_at: end_at)
    end

    it 'does not do anything' do
      # Auto-logout is at 9:40
      expect { action.perform }.not_to change { reservation.reload.actual_end_at }
      expect { action.perform }.not_to change { order_detail.reload.state }
    end
  end

  describe 'an unpurchased reservation' do
    let!(:reservation) { create(:setup_reservation, :yesterday) }

    it 'does not do anything' do
      expect { action.perform }.not_to change { reservation.reload.actual_end_at }
      expect { action.perform }.not_to change { order_detail.reload.state }
      expect { action.perform }.not_to change { order_detail.reload.order_status_id }
    end
  end
end
