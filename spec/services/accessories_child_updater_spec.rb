require "rails_helper"

RSpec.describe Accessories::ChildUpdater do
  let!(:child_order_detail) do
    FactoryGirl.create(
      :order_detail,
      order: order,
      parent_order_detail_id: parent_order_detail.id,
      product: product,
    )
  end

  let(:order) { FactoryGirl.create(:purchased_order, product: product) }
  let(:parent_order_detail) { order.order_details.first }
  let(:product) { FactoryGirl.create(:setup_item) }
  let(:user) { order.user }

  context "when transitioning the parent from new to inprocess" do
    before(:each) do
      expect(parent_order_detail.reload.child_order_details).to eq [child_order_detail]
      parent_order_detail.update_order_status!(user, OrderStatus.inprocess.first)
    end

    it "transitions parent and child to inprocess" do
      expect(parent_order_detail).to be_inprocess
      expect(child_order_detail).to be_inprocess
    end
  end
end
