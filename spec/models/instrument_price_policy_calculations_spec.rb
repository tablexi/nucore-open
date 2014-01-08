require 'spec_helper'

describe InstrumentPricePolicyCalculations do

  subject(:policy) { build :instrument_price_policy }

  let(:now) { Time.zone.now }
  let(:start_at) { Time.zone.parse '2013-12-13 09:00' }
  let(:end_at) { Time.zone.parse '2013-12-14 12:00' }
  let(:duration) { (end_at - start_at) / 60 }
  let(:reservation) { create :setup_reservation, product: policy.product }

  let :old_policy do
    create :old_instrument_price_policy, policy.attributes.merge(
      'usage_mins' => 1,
      'reservation_mins' => 1,
      'overage_mins' => 1,
      'reservation_rate' => policy.usage_rate,
      'overage_rate' => policy.usage_rate
    )
  end


  it 'uses the given order detail to #calculate_cost_and_subsidy' do
    fake_order_detail = double 'OrderDetail', reservation: double('Reservation')
    expect(policy).to receive(:calculate_cost_and_subsidy).with fake_order_detail.reservation
    policy.calculate_cost_and_subsidy_from_order_detail fake_order_detail
  end

  it 'calculates cost based on the given duration and discount' do
    policy.usage_rate = 5
    expect(policy.calculate_cost(120, 0.15).to_f).to eq 1.5
  end

  it 'calculates subsidy based on the given duration and discount' do
    policy.usage_subsidy = 5
    expect(policy.calculate_subsidy(120, 0.15).to_f).to eq 1.5
  end


  describe 'calculating with two effective schedule rules, one discounting one not' do
    before :each do
      policy.product.schedule_rules.first.update_attributes! start_hour: 0, end_hour: 24, on_sat: false, on_sun: false
      policy.product.schedule_rules << create(:weekend_schedule_rule, instrument: policy.product, discount_percent: 0.25, start_hour: 0, end_hour: 24)
    end

    it 'calculates a discount based on the given time and configured schedule rules' do
      expect(policy.calculate_discount(start_at, end_at).round 3).to eq 0.999
    end

    it 'estimates the same as the old instrument price policy' do
      new_estimate = policy.estimate_cost_and_subsidy start_at, end_at
      old_policy.usage_rate = 0
      old_estimate = old_policy.estimate_cost_and_subsidy start_at, end_at
      expect(new_estimate).to eq old_estimate
    end
  end


  describe 'estimating cost and subsidy from an order detail' do
    it 'uses the given order detail to #estimate_cost_and_subsidy' do
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


  describe 'calculating cost and subsidy' do
    before :each do
      reservation.actual_start_at = now
      reservation.actual_end_at = now + 1.hour
    end

    it 'returns #calculate_cancellation_costs if the reservation was cancelled' do
      expect(reservation).to receive(:canceled_at).and_return Time.zone.now
      expect(policy).to receive(:calculate_cancellation_costs).with reservation
      expect(policy).to_not receive :calculate_overage
      expect(policy).to_not receive :calculate_reservation
      expect(policy).to_not receive :calculate_usage
      policy.calculate_cost_and_subsidy reservation
    end

    it 'returns #calculate_usage when configured to charge for usage' do
      policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:usage]
      expect(policy).to receive(:calculate_usage).with reservation
      expect(policy).to_not receive :calculate_overage
      expect(policy).to_not receive :calculate_reservation
      expect(policy).to_not receive :calculate_cancellation_costs
      policy.calculate_cost_and_subsidy reservation
    end

    it 'returns #calculate_overage when configured to charge for overage' do
      policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage]
      expect(policy).to receive(:calculate_overage).with reservation
      expect(policy).to_not receive :calculate_usage
      expect(policy).to_not receive :calculate_reservation
      expect(policy).to_not receive :calculate_cancellation_costs
      policy.calculate_cost_and_subsidy reservation
    end

    it 'returns #calculate_reservation when configured to charge for reservation' do
      policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:reservation]
      expect(policy).to receive(:calculate_reservation).with reservation
      expect(policy).to_not receive :calculate_overage
      expect(policy).to_not receive :calculate_usage
      expect(policy).to_not receive :calculate_cancellation_costs
      policy.calculate_cost_and_subsidy reservation
    end

    it 'returns #estimate_cost_and_subsidy' do
      expect(policy).to receive(:estimate_cost_and_subsidy).with reservation.reserve_start_at, reservation.reserve_end_at
      policy.calculate_reservation reservation
    end

    %w(usage overage).each do |charge_for|
      it "returns nil if actual_start_at is missing and we are charging by #{charge_for}" do
        policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[charge_for.to_sym]
        reservation.stub(:actual_start_at).and_return nil
        expect(policy.calculate_cost_and_subsidy(reservation)).to be_nil
      end

      it "returns nil if actual_end_at is missing and we are charging by #{charge_for}" do
        policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[charge_for.to_sym]
        reservation.stub(:actual_start_at).and_return now
        reservation.stub(:actual_end_at).and_return nil
        expect(policy.calculate_cost_and_subsidy(reservation)).to be_nil
      end
    end

    it 'returns minimum cost if instrument is #free?' do
      policy.stub(:free?).and_return true
      min_cost = 10
      policy.stub(:minimum_cost).and_return min_cost
      expect(policy.calculate_cost_and_subsidy reservation).to eq({ cost: min_cost, subsidy: 0 })
    end

    it 'returns 0 if instrument is #free? and there is no minimum_cost' do
      policy.stub(:free?).and_return true
      policy.stub(:minimum_cost).and_return nil
      expect(policy.calculate_cost_and_subsidy reservation).to eq({ cost: 0, subsidy: 0 })
    end

    it 'calculates reservation costs same as the old policy' do
      old_policy.product.control_mechanism = Relay::CONTROL_MECHANISMS[:manual]
      policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:reservation]
      new_costs = policy.calculate_cost_and_subsidy reservation
      old_costs = old_policy.calculate_cost_and_subsidy reservation
      expect(new_costs).to_not be_nil
      expect(new_costs).to eq old_costs
    end

    it 'calculates usage costs precisely' do
      policy.attributes = {
        usage_subsidy: 10.33,
        usage_rate: 73.20
      }

      policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:usage]
      reservation.actual_start_at = reservation.reserve_start_at
      reservation.actual_end_at = reservation.reserve_end_at - 10.minutes
      new_costs = policy.calculate_cost_and_subsidy reservation
      expect(new_costs[:cost].round 4).to eq 61
      expect(new_costs[:subsidy].round 4).to eq 8.6083
    end

    it 'calculates overage costs precisely' do
      policy.attributes = {
        usage_subsidy: 7,
        usage_rate: 25
      }

      policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage]
      reservation.actual_start_at = reservation.reserve_start_at
      reservation.actual_end_at = reservation.reserve_end_at + 10.minutes
      new_costs = policy.calculate_cost_and_subsidy reservation
      expect(new_costs[:cost].round 4).to eq 29.1667
      expect(new_costs[:subsidy].round 4).to eq 8.1667
    end
  end


  describe 'determining whether or not a cancellation should be penalized' do
    before(:each) { policy.product.stub(:min_cancel_hours).and_return 3 }

    it 'returns true when the cancellation fee applies' do
      reservation = double reserve_start_at: now + 30.minutes, canceled_at: now
      expect(policy.cancellation_penalty?(reservation)).to be_true
    end

    it 'returns false when the cancellation fee does not apply' do
      reservation = double reserve_start_at: now + 4.hours, canceled_at: now
      expect(policy.cancellation_penalty?(reservation)).to be_false
    end
  end


  describe 'calculating cancellation costs' do
    let(:reservation) { double 'Reservation' }

    it 'returns the cancellation cost if penalty applies' do
      policy.stub(:cancellation_penalty?).and_return true
      policy.stub(:cancellation_cost).and_return 5.0
      expect(policy.calculate_cancellation_costs(reservation)).to eq({ cost: policy.cancellation_cost, subsidy: 0})
    end

    it 'returns nil if penalty applies' do
      policy.stub(:cancellation_penalty?).and_return false
      expect(policy.calculate_cancellation_costs(reservation)).to be_nil
    end
  end

end
