require 'spec_helper'

describe InstrumentPricePolicy do
  let(:product) { build_stubbed :instrument, schedule_rules: [] }
  let(:policy) { build_stubbed :instrument_price_policy, usage_rate: 60, product: product }

  let(:now) { Time.zone.now }
  subject(:calculation) { policy.calculate_cost_and_subsidy reservation }

  let(:reservation) do
    build_stubbed :reservation,
          reserve_start_at: now.change(hour: reserve[0], min: reserve[1]),
          reserve_end_at: now.change(hour: reserve[2], min: reserve[3]),
          actual_start_at: now.change(hour: actual[0], min: actual[1]),
          actual_end_at: now.change(hour: actual[2], min: actual[3])
  end

  context 'with a discounted schedule' do
    before do
      policy.minimum_cost = 100
      rules = [build_stubbed(:schedule_rule, start_hour: 0, end_hour: 17),
               build_stubbed(:schedule_rule, start_hour: 17, end_hour: 21, discount_percent: 20)]
      allow(policy.product).to receive(:schedule_rules).and_return rules
    end

    context 'Res 3-4' do
      let(:reserve) { [15, 0, 16, 0] }

      context 'Actual 3-4:15' do
        let(:actual)  { [15, 0, 16, 15] }

        context 'overage' do
          before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage] }

          it { should eq({cost: 100, subsidy: 0}) }
        end
      end

      context 'Actual 3:15-4:15' do
        let(:actual)  { [15, 15, 16, 15] }

        context 'overage' do
          before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage] }

          it { should eq({cost: 100, subsidy: 0}) }
        end
      end
    end

    context 'Res 4-6' do
      let(:reserve) { [16, 0, 18, 0] }

      context 'Actual 4-6' do
        let(:actual)  { [16, 0, 18, 0] }

        context 'overage' do
          before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage] }

          it { should eq({cost: 108, subsidy: 0}) }
        end
      end

      context 'Actual 4:15-5:45' do
        let(:actual)  { [16, 15, 17, 45] }

        context 'overage' do
          before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage] }

          it { should eq({cost: 108, subsidy: 0}) }
        end
      end

      context 'Actual 4-6:15' do
        let(:actual) { [16, 0, 18, 15] }

        context 'overage' do
          before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage] }

          it { should eq({cost: 120, subsidy: 0}) }
        end
      end

      context 'Actual 4:15-6:15' do
        let(:actual) { [16, 15, 18, 15] }

        context 'overage' do
          before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage] }

          it { should eq({cost: 120, subsidy: 0}) }
        end
      end
    end
  end
end
