require 'spec_helper'

describe AutoCanceller do
  before :each do
    # Need to travel later in the day so that previous reservations can be made in the day
    Timecop.travel(Time.zone.parse("#{Date.today.to_s} 12:30:00"))
  end

  after :each do
    Timecop.return
  end

  let(:base_date) { Time.zone.parse("#{Date.today.to_s} 12:30:00") }
  let(:instrument) { FactoryGirl.create :setup_instrument }
  let!(:future_reservation) { FactoryGirl.create :purchased_reservation,
    :product => instrument,
    :reserve_start_at => base_date + 1.day,
    :reserve_end_at => base_date + 1.day + 1.hour }

  let!(:past_reservation) { FactoryGirl.create :purchased_reservation,
    :product => instrument,
    :reserve_start_at => base_date - 2.hours,
    :reserve_end_at => base_date - 1.hour,
    :reserved_by_admin => true}

  let!(:completed_reservation) do
    res = FactoryGirl.create :purchased_reservation,
      :product => instrument,
      :reserve_start_at => base_date - 3.hours,
      :reserve_end_at => base_date - 2.hour,
      :reserved_by_admin => true
    res.order_detail.to_complete!
    res
  end

  let(:cancelled_status) { OrderStatus.cancelled.first }

  let(:canceller) { AutoCanceller.new }

  context 'with auto-cancel minutes' do
    before :each do
      instrument.update_attributes(:auto_cancel_mins => 10, :min_cancel_hours => 1)
    end

    it 'should find the past reservation in cancelable' do
      canceller.cancelable_reservations.to_a.should == [past_reservation]
    end

    it 'should not cancel the future reservation' do
      canceller.cancel_reservations
      future_reservation.order_detail.reload.order_status.should_not == cancelled_status
    end

    it 'should cancel the past reservation' do
      canceller.cancel_reservations
      past_reservation.order_detail.reload.order_status.should == cancelled_status
    end

    it 'should not cancel the completed reservation' do
      canceller.cancel_reservations
      completed_reservation.order_detail.reload.order_status.should_not == cancelled_status
    end

    context 'with cancellation fee' do
      before :each do
        instrument.price_policies.first.update_attributes(:cancellation_cost => 10)
      end

      it 'should charge the fee' do
        canceller.cancel_reservations
        past_reservation.order_detail.reload.actual_cost.to_f.should == 10
      end
    end

  end

  context 'without auto-cancel minutes' do
    before :each do
      instrument.update_attributes(:auto_cancel_mins => 0)
    end

    it 'should not cancel reservations' do
      canceller.cancel_reservations
      past_reservation.order_detail.order_status.should_not == cancelled_status
    end
  end
end
