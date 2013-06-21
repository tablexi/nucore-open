require 'spec_helper'

describe OrderDetail do
  let(:instrument) { FactoryGirl.create(:instrument_with_accessory) }
  let(:accessory) { instrument.accessories.first }
  let(:reservation) { FactoryGirl.create(:purchased_reservation, :product => instrument, :reserve_start_at => 1.day.ago) }
  let(:order_detail) { reservation.order_detail }
  let(:accessorizer) { Accessories::Accessorizer.new(order_detail) }

  before :each do
    order_detail.backdate_to_complete!(Time.zone.now)
  end

  shared_examples_for "an accessory's order detail" do
    it 'belongs to the parent' do
      expect(accessory_order_detail.parent_order_detail).to eq(order_detail)
    end

    it 'belongs to the same order' do
      expect(accessory_order_detail.order).to eq(order_detail.order)
    end

    it 'is for the correct product' do
      expect(accessory_order_detail.product).to eq(accessory)
    end

    it 'is for the same account' do
      expect(accessory_order_detail.account).to eq(order_detail.account)
    end

    it 'is complete' do
      expect(accessory_order_detail).to be_complete
    end

    it 'has pricing' do
      expect(accessory_order_detail.actual_cost).to be
    end

    it "changes the child's account when changing the parent's account" do
      new_account = FactoryGirl.create(:setup_account, :owner => order_detail.user)
      order_detail.update_attributes(:account => new_account)
      expect(accessory_order_detail.reload.account).to eq new_account
    end
  end

  context 'quantity based accessory' do
    let!(:accessory_order_detail) { accessorizer.add_accessory(accessory) }
    it_behaves_like "an accessory's order detail"

    context 'where the reservation time changes' do
      before :each do
        accessory_order_detail.update_attributes(:quantity => 1)
        reservation.update_attributes(:reserve_end_at => reservation.reserve_end_at + 30.minutes)
      end

      it 'does not update the quantity' do
        expect(accessory_order_detail.reload.quantity).to eq(1)
      end
    end
  end

  context 'manual scaled accessory' do
    let(:accessory_order_detail) { accessorizer.add_accessory(accessory) }
    before :each do
      accessorizer.send(:product_accessory, accessory).update_attributes!(:scaling_type => 'manual')
      accessory_order_detail # load
    end

    it_behaves_like "an accessory's order detail"

    it 'has the number of actual usage time as the quantity' do
      expect(accessory_order_detail.quantity).to eq(reservation.actual_duration_mins)
    end

    context 'where the reservation time changes' do
      before :each do
        accessory_order_detail.update_attributes(:quantity => 1)
        reservation.update_attributes(:reserve_end_at => reservation.reserve_end_at + 30.minutes)
      end

      it 'does not update the quantity' do
        expect(accessory_order_detail.reload.quantity).to eq(1)
      end
    end

    context 'where the actual time changes' do
      before :each do
        accessory_order_detail.update_attributes(:quantity => 1)
        reservation.update_attributes(:actual_end_at => reservation.actual_end_at + 30.minutes)
      end

      it 'does not update the quantity' do
        expect(accessory_order_detail.reload.quantity).to eq(1)
      end
    end
  end

  context 'auto scaled accessory' do
    let(:accessory_order_detail) { accessorizer.add_accessory(accessory) }
    before :each do
      accessorizer.send(:product_accessory, accessory).update_attributes(:scaling_type => 'auto')
      accessory_order_detail #load
    end

    it_behaves_like "an accessory's order detail"

    it 'has the number of actual usage time as the quantity' do
      expect(accessory_order_detail.quantity).to eq(reservation.actual_duration_mins)
    end

    context 'where the reservation time changes' do
      before :each do
        accessory_order_detail.update_attributes(:quantity => 1)
        reservation.update_attributes(:reserve_end_at => reservation.reserve_end_at + 30.minutes)
      end

      it 'does not update the quantity' do
        expect(accessory_order_detail.reload.quantity).to eq(1)
      end
    end

    context 'where the actual time changes' do
      before :each do
        reservation.update_attributes(:actual_end_at => reservation.actual_end_at + 30.minutes)
      end

      it 'updates the quantity' do
        expect(accessory_order_detail.reload.quantity).to eq(reservation.actual_duration_mins)
      end
    end
  end
end