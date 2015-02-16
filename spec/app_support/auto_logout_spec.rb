require 'spec_helper'

describe AutoLogout do
  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }
  let(:relay) { build_stubbed(:relay, auto_logout: true) }
  before { allow_any_instance_of(Instrument).to receive(:relay).and_return relay }

  describe 'a new reservation' do
    let!(:reservation) { create(:purchased_reservation, :yesterday) }

    it 'completes the reservation' do
      expect { action.perform }.to change { order_detail.reload.state }.from('new').to('complete')
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
end
