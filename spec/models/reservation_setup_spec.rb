require 'spec_helper'

describe Reservation do
  let(:instrument) { FactoryGirl.create(:setup_instrument) }
  let(:user) { FactoryGirl.create(:user) }
  let(:reservation) { FactoryGirl.create(:purchased_reservation, :user => user, :product => :instrument) }
  
  describe 'facility setup' do
    let(:facility) { FactoryGirl.create(:setup_facility) }
    it 'should be saved' do
      facility.should be_persisted
    end

    it 'should have an account' do
      facility.facility_accounts.should_not be_empty
    end

    it 'should have a new price group' do
      facility.price_groups.should_not be_empty
    end

  end

  describe 'instrument setup' do
    it 'should be valid' do
      instrument = FactoryGirl.build(:setup_instrument)
      instrument.should be_valid
    end

    it 'should be saved' do
      instrument.should be_persisted
    end

    it 'should have a facility' do
      instrument.facility.should be_persisted
    end

    it 'should have a facility_account' do
      instrument.facility_account.should be
    end

    it 'should have a schedule rule' do
      instrument.schedule_rules.should_not be_empty
      instrument.schedule_rules.first.start_hour.should == 9
      instrument.schedule_rules.first.end_hour.should == 17
    end

    it 'should have a price group' do
      instrument.price_groups.should_not be_empty
    end

    it 'should have the price group product' do
      instrument.price_group_products.should_not be_empty
    end

    context 'price policies' do
      it 'should have a price policy' do
        instrument.price_policies.should_not be_empty
      end

      it 'should be persisted' do
        instrument.price_policies.all? { |pp| pp.persisted? }
      end

      it 'should be the newly created price group' do
        instrument.price_policies.first.price_group.facility.should_not be_nil
        instrument.price_policies.first.price_group.name.should =~ /Price Group/
      end
    end
  end

  describe 'account setup' do
    let(:account) { FactoryGirl.create(:setup_account) }
    it 'should be persisted' do
      account.should be_persisted
    end

    it 'should have an owner' do
      account.owner.should be
    end
  end

  describe 'order setup' do
    let (:product) { FactoryGirl.create(:setup_instrument) }
    let (:order) { FactoryGirl.create(:setup_order, :product => product) }

    it 'should have an order detail' do
      order.order_details.should_not be_empty
    end

    it 'should not be validated' do
      order.state.should == 'new'
    end
  end

  describe 'reservation setup' do
    describe 'unpurchased' do
      let(:reservation) { FactoryGirl.create(:setup_reservation) }

      it 'should be saved' do
        reservation.should be_persisted
      end

      it 'should be new' do
        reservation.order.state.should == 'new'
      end
    end

    describe 'validated reservation' do
      let(:reservation) { FactoryGirl.create(:validated_reservation) }
      
      it 'should be saved' do
        reservation.should be_persisted
      end

      it 'should be validated' do
        reservation.order.state.should == 'validated'
      end
    end

    describe 'purchased reservation' do
      let(:reservation) { FactoryGirl.create(:purchased_reservation) }
      
      it 'should be saved' do
        reservation.should be_persisted
      end

      it 'should be purchased' do
        reservation.order.reload.state.should == 'purchased'
      end
    end

  end
end
