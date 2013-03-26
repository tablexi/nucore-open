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
end
