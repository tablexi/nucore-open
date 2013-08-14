require 'spec_helper'

describe Cart do
  describe "instrument_only_carts" do
    let(:carts) { Cart.abandoned_carts }
    let(:instrument) { FactoryGirl.create(:setup_instrument) }
    let(:item) { FactoryGirl.create(:setup_item, :facility => instrument.facility) }
    before :each do
      @purchased_instrument_order = FactoryGirl.create(:purchased_reservation, :product => instrument, :reserve_start_at => 2.hours.from_now, :reserve_end_at => 3.hours.from_now).order
      @instrument_order = FactoryGirl.create(:setup_reservation, :product => instrument).order

      @instrument_and_item_order = FactoryGirl.create(:setup_reservation, :product => instrument).order
      @instrument_and_item_order.add(item, 1)

      @two_instrument_order = FactoryGirl.create(:setup_reservation, :product => instrument).order
      @two_instrument_order.add(@two_instrument_order.order_details.first.product, 1)

      @item_order = FactoryGirl.create(:setup_order, :product => item)
    end

    # setup is expensive, so only do it once and test several things at once
    it 'should include the proper orders' do
      carts.should_not include @purchased_instrument_order
      carts.should include @instrument_order
      carts.should_not include @instrument_and_item_order
      carts.should_not include @two_instrument_order
      carts.should_not include @item_order
    end


    context 'destroy_all_instrument_only_carts' do
      let(:all_orders) { Order.all }
      before :each do
        Cart.destroy_all_instrument_only_carts
      end

      it 'should have removed only the orders it should have' do
        all_orders.should include @purchased_instrument_order
        all_orders.should_not include @instrument_order
        all_orders.should include @instrument_and_item_order
        all_orders.should include @two_instrument_order
        all_orders.should include @item_order
      end
    end

    context 'destroy_all_instrument_only_carts with time' do
      it 'should not remove if the order has been updated since the time' do
        Cart.destroy_all_instrument_only_carts(1.day.ago)
        Order.all.should include @instrument_order
      end

      it 'should destroy if the order has not been updated since the time' do
        Cart.destroy_all_instrument_only_carts(Time.zone.now)
        Order.all.should_not include @instrument_order
      end
    end
  end
end