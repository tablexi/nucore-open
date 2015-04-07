require 'spec_helper'

describe Reservation do
  context 'started reservation completed by cron job' do
    subject do
      res = FactoryGirl.create :purchased_reservation,
          :reserve_start_at => Time.zone.parse("#{Date.today.to_s} 10:00:00") - 2.days,
          :reserve_end_at => Time.zone.parse("#{Date.today.to_s} 10:00:00") - 2.days + 1.hour,
          :actual_start_at => Time.zone.parse("#{Date.today.to_s} 10:00:00") - 2.days

      # needs to have a relay
      res.product.relay = FactoryGirl.create(:relay_dummy, :instrument => res.product)
      res.order_detail.change_status!(OrderStatus.find_by_name('Complete'))
      res
    end

    # Confirming setup
    it { should_not be_has_actuals }
    it { should be_complete }

    it 'should have a relay' do
      subject.product.relay.should be_a RelayDummy
    end

    its(:actual_end_at) { should be_nil }
    its(:actual_start_at) { should be }

    it { should_not be_can_switch_instrument_on }
    it { should_not be_can_switch_instrument_off }
  end

  context '#other_reservations_using_relay' do
    let!(:reservation_done) { create(:purchased_reservation, :yesterday, actual_start_at: 1.day.ago) }

    context 'with no other running reservations' do
      it 'returns nothing' do
        expect(reservation_done.other_reservations_using_relay).to be_empty
      end
    end

    context 'with one other running reservation' do
      let!(:reservation_running) { create(:purchased_reservation, product: reservation_done.product, reserve_start_at: 30.minutes.ago, reserve_end_at: 30.minutes.from_now, actual_start_at: 30.minutes.ago) }

      it 'returns the running reservation' do
        expect(reservation_done.other_reservations_using_relay).to match_array([reservation_running])
      end
    end

    context 'with a running reservation for another product using the same schedule' do
      let!(:product_shared) { create(:setup_instrument, schedule: reservation_done.product.schedule) }
      let!(:reservation_shared_running) { create(:purchased_reservation, product: product_shared, reserve_start_at: 30.minutes.ago, reserve_end_at: 30.minutes.from_now, actual_start_at: 30.minutes.ago) }

      it 'returns the running reservation' do
        expect(reservation_done.other_reservations_using_relay).to match_array([reservation_shared_running])
      end
    end
  end
end
