require 'spec_helper'

describe Accessories::ChildUpdater do
  let(:order) { mock_model Order }
  let(:order_detail) do
    build_stubbed :order_detail,
               order: order,
               child_order_details: [],
               attributes: {
                order_id: order.id
               }
  end

  describe 'update_children' do
    let(:child_order_detail) { build_stubbed :order_detail, order: order }
    before { allow(order_detail).to receive(:child_order_details).and_return [child_order_detail] }

    it 'updates the child' do
      expect(child_order_detail).to receive(:assign_actual_price)
      expect(child_order_detail).to receive(:save)
      expect(order_detail.update_children).to eq([child_order_detail])
    end
  end
end
