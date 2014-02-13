require 'spec_helper'

describe Accessories::Accessorizer do
  let(:accessory1) { mock_model Product }
  let(:product_accessory1) { mock_model ProductAccessory, scaling_type: 'quantity', accessory: accessory1 }
  let(:accessory2) { mock_model Product }
  let(:product_accessory2) { mock_model ProductAccessory, scaling_type: 'auto', accessory: accessory2 }

  let(:product) { mock_model Instrument, accessories: [accessory1, accessory2] }
  before do
    allow(product).to receive(:product_accessory_by_id).with(accessory1.id).and_return product_accessory1
    allow(product).to receive(:product_accessory_by_id).with(accessory2.id).and_return product_accessory2
  end

  let(:order) { mock_model Order }
  let(:order_detail) do
    # mock_model OrderDetail,
    build_stubbed :order_detail,
               product: product,
               order: order,
               child_order_details: [],
               attributes: {
                order_id: order.id
               }
  end

  subject(:accessorizer) { described_class.new(order_detail) }

  describe 'available_accessory_order_details' do
    context 'when no accessories have been added' do

      it 'has both accessories as avaiable' do
        expect(accessorizer.available_accessories).to eq([accessory1, accessory2])
      end

      it 'builds an order detail for both accessories' do
        od1 = double 'OD1'
        od2 = double 'OD2'
        expect(accessorizer).to receive(:build_accessory_order_detail).with(accessory1).and_return od1
        expect(accessorizer).to receive(:build_accessory_order_detail).with(accessory2).and_return od2
        expect(accessorizer.available_accessory_order_details).to eq([od1, od2])
      end
    end

    context 'when the order already has an accessory' do
      let(:child_order_detail) { mock_model OrderDetail, product: accessory1, order: order }
      before { allow(order_detail).to receive(:child_order_details).and_return [child_order_detail] }

      it 'only has accessory2 as an available accessory' do
        expect(accessorizer.available_accessories).to eq([accessory2])
      end

      it 'builds an order detail or accessory2' do
        od = double
        expect(accessorizer).to receive(:build_accessory_order_detail).with(accessory2).and_return(od)
        expect(accessorizer.available_accessory_order_details).to eq([od])
      end
    end
  end

  describe 'build_accessory_order_detail' do
    context 'an invalid accessory' do
      let(:invalid_accessory) { mock_model Product }
      it 'returns nil' do
        od = accessorizer.build_accessory_order_detail(invalid_accessory)
        expect(od).to be_nil
      end
    end

    it 'builds an order detail' do
      od = accessorizer.build_accessory_order_detail(accessory1)
      expect(od.product).to eq(accessory1)
      expect(od.parent_order_detail).to eq(order_detail)
      expect(od.order_id).to eq(order.id)
      expect(od.quantity).to eq(1)
      expect(od).to_not be_quantity_as_time
    end
  end
end
