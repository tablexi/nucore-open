require 'spec_helper'

describe InstrumentPricePolicyCalculations do

  subject(:policy) { build :instrument_price_policy }


  it 'uses the given order detail to #calculate_cost_and_subsidy' do
    fake_order_detail = double 'OrderDetail', reservation: double('Reservation')
    expect(policy).to receive(:calculate_cost_and_subsidy).with fake_order_detail.reservation
    policy.calculate_cost_and_subsidy_from_order_detail fake_order_detail
  end

  it 'calculates cost based on the given duration and discount' do
    policy.usage_rate = 5
    expect(policy.usage_mins).to eq 60
    expect(policy.calculate_cost 120, 0.15).to eq 1.5
  end

  it 'calculates subsidy based on the given duration and discount' do
    policy.usage_subsidy = 5
    expect(policy.usage_mins).to eq 60
    expect(policy.calculate_subsidy 120, 0.15).to eq 1.5
  end

  it 'calculates a discount based on the given time and configured schedule rules' do
    policy.product.schedule_rules.first.update_attributes! start_hour: 0, end_hour: 24, on_sat: false, on_sun: false
    policy.product.schedule_rules << create(:weekend_schedule_rule, instrument: policy.product, discount_percent: 0.25, start_hour: 0, end_hour: 24)
    start_at = Time.zone.parse '2013-12-13 09:00'
    end_at = Time.zone.parse '2013-12-14 12:00'
    expect(policy.calculate_discount(start_at, end_at).round 3).to eq 0.999
  end


  describe '#estimate_cost_and_subsidy_from_order_detail' do
    it 'uses the given order detail to #estimate_cost_and_subsidy' do
      now = Time.now
      fake_reservation = double 'Reservation', reserve_start_at: now, reserve_end_at: now + 1.hour
      fake_order_detail = double 'OrderDetail', reservation: fake_reservation
      expect(policy).to receive(:estimate_cost_and_subsidy).with fake_reservation.reserve_start_at, fake_reservation.reserve_end_at
      policy.estimate_cost_and_subsidy_from_order_detail fake_order_detail
    end

    it 'returns nil if the given order detail does not have a reservation' do
      fake_order_detail = double 'OrderDetail', reservation: nil
      expect(policy.estimate_cost_and_subsidy_from_order_detail fake_order_detail).to be_nil
    end
  end


  describe 'estimating cost and subsidy' do
    let(:start_at) { Time.zone.now + 1.hour }
    let(:end_at) { start_at + 1.hour }
    let(:duration) { (end_at - start_at) / 60 }

    it 'returns nil if purchase is restricted' do
      policy.stub(:restrict_purchase?).and_return true
      expect(policy.estimate_cost_and_subsidy(start_at, end_at)).to be_nil
    end

    it 'returns nil if purchase if end_at is before start_at' do
      expect(policy.estimate_cost_and_subsidy(end_at, start_at)).to be_nil
    end

    it 'returns nil if purchase if end_at equals start_at' do
      expect(policy.estimate_cost_and_subsidy(start_at, start_at)).to be_nil
    end

    it 'gives a zero cost and subsidy if instrument is free to use and there is no minimum cost' do
      policy.stub(:free?).and_return true
      policy.stub(:minimum_cost).and_return nil
      costs = policy.estimate_cost_and_subsidy start_at, end_at
      expect(costs[:cost]).to eq 0
      expect(costs[:subsidy]).to eq 0
    end

    it 'gives minimum cost and zero subsidy if instrument is free to use and there is a minimum cost' do
      policy.stub(:free?).and_return true
      policy.stub(:minimum_cost).and_return 10
      costs = policy.estimate_cost_and_subsidy start_at, end_at
      expect(costs[:cost]).to eq 10
      expect(costs[:subsidy]).to eq 0
    end

    it 'gives the calculated cost and subsidy' do
      discount = 0.999
      expect(policy).to receive(:calculate_discount).with(start_at, end_at).and_return discount
      cost = 5.00
      expect(policy).to receive(:calculate_cost).with(duration, discount).and_return cost
      subsidy = 1.00
      expect(policy).to receive(:calculate_subsidy).with(duration, discount).and_return subsidy
      results = policy.estimate_cost_and_subsidy start_at, end_at
      expect(results[:cost]).to eq cost
      expect(results[:subsidy]).to eq subsidy
    end

    it 'gives the minimum cost and zero subsidy if below minimum cost' do
      discount = 0
      expect(policy).to receive(:calculate_discount).with(start_at, end_at).and_return discount
      cost = 5.00
      expect(policy).to receive(:calculate_cost).with(duration, discount).and_return cost
      subsidy = 6.00
      expect(policy).to receive(:calculate_subsidy).with(duration, discount).and_return subsidy
      min_cost = 3.00
      policy.stub(:minimum_cost).and_return min_cost
      results = policy.estimate_cost_and_subsidy start_at, end_at
      expect(results[:cost]).to eq min_cost
      expect(results[:subsidy]).to eq 0
    end
  end


end
