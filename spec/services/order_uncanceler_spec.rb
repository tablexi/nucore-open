require 'spec_helper'

describe OrderUncanceler do
  let(:cancel_status) { OrderStatus.cancelled.first }
  let(:uncanceler) { OrderUncanceler.new }

  context 'with an item' do
    let(:item) { FactoryGirl.create(:setup_item) }
    let(:order) { FactoryGirl.create(:purchased_order, :product => item) }
    let(:order_detail) { order.order_details.first }

    it 'should not uncancel a not-canceled order' do
      uncanceler.uncancel_to_complete(order_detail)
      order_detail.should_not be_changed
      order_detail.should_not be_cancelled
    end

    context 'with a canceled order' do
      before :each do
        order_detail.update_order_status!(order.user, cancel_status)
        order_detail.should be_cancelled
        uncanceler.uncancel_to_complete(order_detail)
      end

      it 'should uncancel' do
        order_detail.should be_complete
      end

      it 'should have a price' do
        order_detail.actual_cost.should > 0
      end

      it 'should have a price policy' do
        order_detail.price_policy.should be
      end
    end
  end

  context 'with a reservation' do
    let(:reservation) { FactoryGirl.create(:purchased_reservation, :reserve_start_at => 1.day.ago, :reserve_end_at => 23.hours.ago, :reserved_by_admin => true) }
    let(:order_detail) { reservation.order_detail }
    before :each do
      order_detail.product.price_policies.update_all(:start_date => 7.days.ago)
      reservation.order_detail.backdate_to_complete!(Time.zone.now)
      order_detail.should be_complete
    end

    context 'and the reservation is canceled' do
      before :each do
        order_detail.update_order_status!(order_detail.user, cancel_status, :admin => true)
        order_detail.should be_cancelled
        uncanceler.uncancel_to_complete(order_detail)
      end

      it 'should make complete' do
        order_detail.should be_complete
      end

      it 'should have a price' do
        order_detail.actual_cost.should > 0
      end

      it 'should have a price policy' do
        order_detail.price_policy.should be
      end

      it 'should set the fulfilled date to the reservation end time' do
        order_detail.fulfilled_at.should eq(reservation.reserve_end_at)
      end

      it 'should set the actuals off the reservation' do
        reservation.reload.actual_start_at.should eq(reservation.reserve_start_at)
        reservation.reload.actual_end_at.should eq(reservation.reserve_end_at)
      end
    end
  end
end
