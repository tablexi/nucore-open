require 'spec_helper'

describe AutoLogout, :timecop_freeze do
  let(:now) { Time.zone.now.change(hour: 9, min: 31)  }

  let(:action) { described_class.new }
  let(:order_detail) { reservation.order_detail }
  let(:relay) { build_stubbed(:relay, auto_logout: true, auto_logout_minutes: 10) }
  before { allow_any_instance_of(Instrument).to receive(:relay).and_return relay }

  describe 'a started reservation past log out time' do
    let!(:reservation) { create(:purchased_reservation, :yesterday, actual_start_at: 1.day.ago) }

    before do
      reservation.product.price_policies.destroy_all
      create :instrument_usage_price_policy, price_group: reservation.product.facility.price_groups.last, usage_rate: 1, product: reservation.product
      reservation.reload

      expect(relay).to receive(:deactivate)
    end

    it 'completes the reservation' do
      expect { action.perform }.to change { order_detail.reload.state }.from('new').to('complete')
    end

    it 'does not set the reservation actual end at' do
      expect { action.perform }.to_not change { order_detail.reservation.reload.actual_end_at }.from(nil)
    end

    it 'does not set the reservation price policy' do
      expect { action.perform }.to_not change { order_detail.reload.price_policy }.from(nil)
    end

    it 'is a problem order' do
      expect { action.perform }.to change { order_detail.reload.problem_order? }.to(true)
    end

    it 'deactivates the relay' do
      # see before block for deactivate expectation
      action.perform
    end
  end


  describe 'a new reservation prior to log out time' do
    let!(:reservation) do
      start_at = 30.minutes.ago # 9:01am
      end_at = 1.minute.ago    # 9:30am

      # Auto-logout is at 9:40

      create(:purchased_reservation,
          product: create(:setup_instrument, min_reserve_mins: 1),
          actual_start_at: 30.minutes.ago,
          reserve_start_at: start_at,
          reserve_end_at: end_at)
    end

    before do
      expect(relay).to_not receive(:deactivate)

      action.perform
      reservation.reload
      order_detail.reload
    end

    include_examples 'it does not complete order'

    it 'does not deactivate the relay' do
      # see before block for deactivate expectation
      action.perform
    end
  end

  describe 'a running new reservation' do
    let!(:reservation) { create(:purchased_reservation, reserve_start_at: 30.minutes.ago, reserve_end_at: 30.minutes.from_now, actual_start_at: 30.minutes.ago) }

    before do
      expect(relay).to_not receive(:deactivate)

      action.perform
      reservation.reload
      order_detail.reload
    end

    include_examples 'it does not complete order'

    it 'does not deactivate the relay' do
      # see before block for deactivate expectation
      action.perform
    end
  end

  describe 'an unpurchased reservation' do
    let!(:reservation) { create(:setup_reservation, :yesterday) }

    before do
      action.perform
      reservation.reload
      order_detail.reload
    end

    include_examples 'it does not complete order'
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

  describe 'ignores other problem reservations' do
    let!(:product) { create(:setup_instrument, min_reserve_mins: 1) }
    let!(:reservation_problem) { create(:purchased_reservation, :yesterday, product: product, actual_start_at: 1.day.ago, actual_end_at: nil) }
    let!(:reservation_running) { create(:purchased_reservation, product: product, reserve_start_at: 30. minutes.ago, reserve_end_at: 11.minute.ago, actual_start_at: 30.minutes.ago) }

    before do
      reservation_problem.complete!
      expect(relay).to receive(:deactivate)
    end

    it 'deactivates the relay' do
      # see before block for deactivate expectation
      action.perform
    end
  end
end
