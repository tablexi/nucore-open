require 'spec_helper'

describe Reservation do
  let(:instrument) { FactoryGirl.create(:setup_instrument) }
  let(:user) { FactoryGirl.create(:user) }
  let(:reservation) { FactoryGirl.create(:purchased_reservation, :user => user, :product => :instrument) }
  
  describe 'facility setup' do
    let(:facility) { FactoryGirl.create(:setup_facility) }
    it 'should be saved' do
      expect(facility).to be_persisted
    end

    it 'should have an account' do
      expect(facility.facility_accounts).not_to be_empty
    end

    it 'should have a new price group' do
      expect(facility.price_groups).not_to be_empty
    end

  end

  describe 'instrument setup' do
    it 'should be valid' do
      instrument = FactoryGirl.build(:setup_instrument)
      expect(instrument).to be_valid
    end

    it 'should be saved' do
      expect(instrument).to be_persisted
    end

    it 'should have a facility' do
      expect(instrument.facility).to be_persisted
    end

    it 'should have a facility_account' do
      expect(instrument.facility_account).to be
    end

    it 'should have a schedule rule' do
      expect(instrument.schedule_rules).not_to be_empty
      expect(instrument.schedule_rules.first.start_hour).to eq(9)
      expect(instrument.schedule_rules.first.end_hour).to eq(17)
    end

    it 'should have a price group' do
      expect(instrument.price_groups).not_to be_empty
    end

    it 'should have the price group product' do
      expect(instrument.price_group_products).not_to be_empty
    end

    context 'price policies' do
      it 'should have a price policy' do
        expect(instrument.price_policies).not_to be_empty
      end

      it 'should be persisted' do
        instrument.price_policies.all? { |pp| pp.persisted? }
      end

      it 'should be the newly created price group' do
        expect(instrument.price_policies.first.price_group.facility).not_to be_nil
        expect(instrument.price_policies.first.price_group.name).to match(/Price Group/)
      end
    end
  end

  describe 'account setup' do
    let(:account) { FactoryGirl.create(:setup_account) }
    it 'should be persisted' do
      expect(account).to be_persisted
    end

    it 'should have an owner' do
      expect(account.owner).to be
    end
  end

  describe 'order setup' do
    let (:product) { FactoryGirl.create(:setup_instrument) }
    let (:order) { FactoryGirl.create(:setup_order, :product => product) }

    it 'should have an order detail' do
      expect(order.order_details).not_to be_empty
    end

    it 'should not be validated' do
      expect(order.state).to eq('new')
    end
  end

  describe 'reservation setup' do
    describe 'unpurchased' do
      let(:reservation) { FactoryGirl.create(:setup_reservation) }

      it 'should be saved' do
        expect(reservation).to be_persisted
      end

      it 'should be new' do
        expect(reservation.order.state).to eq('new')
      end
    end

    describe 'validated reservation' do
      let(:reservation) { FactoryGirl.create(:validated_reservation) }
      
      it 'should be saved' do
        expect(reservation).to be_persisted
      end

      it 'should be validated' do
        expect(reservation.order.state).to eq('validated')
      end
    end

    describe 'purchased reservation' do
      let(:reservation) { FactoryGirl.create(:purchased_reservation) }
      
      it 'should be saved' do
        expect(reservation).to be_persisted
      end

      it 'should be purchased' do
        expect(reservation.order.reload.state).to eq('purchased')
      end
    end

  end
end
