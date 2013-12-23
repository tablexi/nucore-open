require 'spec_helper'

describe InstrumentPricePolicy do

  subject(:policy) { build :instrument_price_policy }

  %w(minimum_cost usage_subsidy cancellation_cost).each do |attr|
    it { should validate_numericality_of(attr.to_sym).is_greater_than_or_equal_to 0 }
    it { should allow_value(nil).for attr.to_sym }
  end

  %w(reservation_rate reservation_subsidy overage_rate overage_subsidy reservation_mins overage_mins).each do |attr|
    it { should_not allow_value(5.0).for attr.to_sym }
    it { should allow_value(nil).for attr.to_sym }
  end

  it { should ensure_inclusion_of(:charge_for).in_array described_class::CHARGE_FOR.values }


  describe 'usage rate validations' do
    it { should validate_numericality_of(:usage_rate).is_greater_than_or_equal_to 0 }

    it 'validates presence of usage rate if purchase is not restricted' do
      policy.stub(:restrict_purchase?).and_return false
      should validate_presence_of :usage_rate
    end

    it 'does not validate presence of usage rate if purchase is restricted' do
      policy.stub(:restrict_purchase?).and_return true
      should_not validate_presence_of :usage_rate
    end
  end


  describe 'validation using #subsidy_less_than_rate?' do
    it 'gives an error if usage_subsidy > usage_rate' do
      expect(policy).to be_valid
      policy.usage_subsidy = 15
      policy.usage_rate = 5
      expect(policy).to_not be_valid
      expect(policy.errors[:usage_subsidy]).to be_present
    end

    it 'does not give an error if usage_subsidy < usage_rate' do
      expect(policy).to be_valid
      policy.usage_subsidy = 15
      policy.usage_rate = 25
      expect(policy).to be_valid
    end
  end


  describe 'before save' do
    it 'sets the usage subsidy to 0 before save if there is a usage_rate' do
      expect(policy.usage_rate).to be_present
      policy.usage_subsidy = nil
      expect(policy.save).to be_true
      expect(policy.reload.usage_subsidy).to eq 0
    end

    it 'does not set the usage subsidy before save if there is a usage_rate and it is already set' do
      expect(policy.usage_rate).to be_present
      subsidy = policy.usage_rate - 0.25
      policy.usage_subsidy = subsidy
      expect(policy.save).to be_true
      expect(policy.reload.usage_subsidy).to eq subsidy
    end

    it 'does not set the usage subsidy before save if there is no usage_rate' do
      policy.stub(:restrict_purchase?).and_return true
      policy.usage_rate = nil
      policy.usage_subsidy = nil
      expect(policy.save).to be_true
      expect(policy.reload.usage_subsidy).to be_nil
    end

    it 'always sets usage_mins to 60' do
      policy.usage_mins = 0
      expect(policy.save).to be_true
      expect(policy.usage_mins).to eq 60
    end
  end


  describe 'after create' do
    it 'creates a PriceGroupProduct with default reservation window if one does not exist' do
      pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(policy.price_group.id, policy.product.id)
      expect(pgp).to be_nil
      expect(policy.save).to be_true
      pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(policy.price_group.id, policy.product.id)
      expect(pgp.reservation_window).to eq PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
    end

    it 'does not create a PriceGroupProduct with default reservation window if one exists' do
      PriceGroupProduct.create(
        price_group: policy.price_group,
        product: policy.product,
        reservation_window: PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
      )

      expect(PriceGroupProduct).to_not receive :create
      expect(policy.save).to be_true
    end
  end


  it 'returns the date for upcoming policies' do
    instrument = policy.product
    price_group = policy.price_group
    create :instrument_price_policy, start_date: Date.today, price_group: price_group, product: instrument
    ipp2 = create :instrument_price_policy, start_date: Date.today + 7.days, price_group: price_group, product: instrument
    ipp3 = create :instrument_price_policy, start_date: Date.today + 14.days, price_group: price_group, product: instrument

    expect(described_class.next_date(instrument).to_date).to eq ipp2.start_date.to_date
    next_dates = described_class.next_dates instrument
    expect(next_dates.size).to eq 2
    expect(next_dates).to include ipp2.start_date.to_date
    expect(next_dates).to include ipp3.start_date.to_date
  end


  describe '#reservation_window' do
    it 'returns 0 if there is no PriceGroupProduct' do
      expect(policy.reservation_window).to eq 0
    end

    it 'returns the reservation window from the after created PriceGroupProduct' do
      expect(policy.save).to be_true
      pgp = PriceGroupProduct.find_by_price_group_id_and_product_id(policy.price_group.id, policy.product.id)
      expect(policy.reservation_window).to eq pgp.reservation_window
    end
  end


  describe '#has_subsidy?' do
    it 'has a subsidy if the attribute is greater than 0' do
      policy.usage_subsidy = 9.0
      expect(policy).to have_subsidy
    end

    it 'does not have a subsidy if the attribute is 0' do
      policy.usage_subsidy = 0
      expect(policy).to_not have_subsidy
    end

    it 'does not have a subsidy if the attribute does not exist' do
      policy.usage_subsidy = nil
      expect(policy).to_not have_subsidy
    end
  end


  describe '#free?' do
    it 'is free if the usage rate is 0' do
      policy.usage_rate = 0
      expect(policy).to be_free
    end

    it 'is not free if the usage rate is greater than 0' do
      policy.usage_rate = 5.0
      expect(policy).to_not be_free
    end
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


  it 'uses the given order detail to #calculate_cost_and_subsidy' do
    fake_order_detail = double 'OrderDetail', reservation: double('Reservation')
    expect(policy).to receive(:calculate_cost_and_subsidy).with fake_order_detail.reservation
    policy.calculate_cost_and_subsidy_from_order_detail fake_order_detail
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
