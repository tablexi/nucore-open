require 'spec_helper'

describe SimpleInstrumentPricePolicy do

  subject(:policy) { build :simple_instrument_price_policy }

  %w(minimum_cost usage_subsidy cancellation_cost).each do |attr|
    it { should validate_numericality_of(attr.to_sym).is_greater_than_or_equal_to 0 }
    it { should allow_value(nil).for attr.to_sym }
  end

  %w(reservation_rate reservation_subsidy overage_rate overage_subsidy).each do |attr|
    it { should_not allow_value(5.0).for attr.to_sym }
    it { should allow_value(nil).for attr.to_sym }
  end
  

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
    instrument.instrument_price_policies.create( attributes_for(:instrument_price_policy, start_date: Date.today, price_group: price_group) )
    ipp2 = instrument.instrument_price_policies.create( attributes_for(:instrument_price_policy, start_date: Date.today + 7.days, price_group: price_group) )
    ipp3 = instrument.instrument_price_policies.create( attributes_for(:instrument_price_policy, start_date: Date.today + 14.days, price_group: price_group) )

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
end
