require 'spec_helper'

describe AutoLogout do
  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }
  let(:relay) { build_stubbed(:relay, auto_logout: true) }
  before { allow_any_instance_of(Instrument).to receive(:relay).and_return relay }

  describe 'a new reservation' do
    let!(:reservation) { create(:purchased_reservation, :yesterday, actual_start_at: 1.day.ago) }

    before do
      expect(relay).to receive(:deactivate)
    end

    it 'completes the reservation' do
      expect { action.perform }.to change { order_detail.reload.state }.from('new').to('complete')
    end

    it 'deactivates the relay' do
      # see before block for deactivate expectation
      action.perform
    end
  end

  describe 'a running new reservation' do
    let!(:reservation) { create(:purchased_reservation, reserve_start_at: 30.minutes.ago, reserve_end_at: 30.minutes.from_now, actual_start_at: 30.minutes.ago) }

    before do
      expect(relay).to_not receive(:deactivate)
    end

    it 'does not complete the reservation' do
      expect { action.perform }.to_not change { order_detail.reload.state }
    end

    it 'does not deactivate the relay' do
      # see before block for deactivate expectation
      action.perform
    end
  end

  describe 'an unpurchased reservation' do
    let!(:reservation) { create(:setup_reservation, :yesterday) }

    it 'does not do anything' do
      expect { action.perform }.not_to change { reservation.reload.actual_end_at }
      expect(order_detail.state).to eq('new')
      expect(order_detail.order_status_id).to be_blank
    end
  end

  describe 'the following running reservation' do
    let!(:reservation_done) { create(:purchased_reservation, :yesterday, actual_start_at: 1.day.ago) }
    let!(:reservation_running) { create(:purchased_reservation, product: reservation_done.product, reserve_start_at: 30.minutes.ago, reserve_end_at: 30.minutes.from_now, actual_start_at: 30.minutes.ago) }

    before do
      expect(relay).to_not receive(:deactivate)
    end

    it 'does not deactivate the relay' do
      # see before block for deactivate expectation
      action.perform
    end
  end
end
