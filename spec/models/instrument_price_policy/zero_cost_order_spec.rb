require 'spec_helper'

describe InstrumentPricePolicy do
  before :each do
    @instrument = FactoryGirl.create(:setup_instrument)
    @instrument.price_policies.count.should == 1
    @price_policy = @instrument.price_policies.first
    @price_policy.update_attributes(:usage_rate => nil,
                                    :usage_subsidy => nil,
                                    :reservation_rate => 0,
                                    :reservation_subsidy => 0,
                                    :overage_rate => nil,
                                    :overage_subsidy => nil,
                                    :minimum_cost => 0,
                                    :cancellation_cost => 0)
    
    @reservation = FactoryGirl.create(:purchased_reservation, :product => @instrument,
      :reserve_start_at => 1.day.ago, :reserve_end_at => 1.day.ago + 1.hour)
    @order_detail = @reservation.reload.order_detail
    @order_detail.assign_estimated_price
  end

  it 'should have estimated costs at zero' do
    @order_detail.estimated_cost.should == 0
    @order_detail.estimated_subsidy.should == 0
  end

  it 'should not have actual prices set' do
    @order_detail.actual_cost.should be_nil
    @order_detail.actual_subsidy.should be_nil
  end

  it 'should not have a price policy set' do
    @order_detail.price_policy.should be_nil
  end

  context 'completed' do
    before :each do
      @order_detail.change_status! OrderStatus.find_by_name('Complete')
      @order_detail.state.should == 'complete'
    end

    it 'should have actual prices set' do
      @order_detail.actual_cost.should == 0
      @order_detail.actual_subsidy.should == 0
    end

    it 'should have a price policy set' do
      @order_detail.price_policy.should == @price_policy
    end
  end

end