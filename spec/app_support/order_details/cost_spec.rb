require 'spec_helper'

describe OrderDetails::Cost do
  describe '#final_total' do
    context 'with actual totals' do
      let(:cost) do
        OrderDetails::Cost.new([
          build(:order_detail, actual_cost: 3, actual_subsidy: 0),
          build(:order_detail, actual_cost: 5, actual_subsidy: 0)])
      end

      it 'sums all totals' do
        cost.final_total.should eq(8)
      end
    end

    context 'with estimated totals' do
      let(:cost) do
        OrderDetails::Cost.new([
          build(:order_detail, estimated_cost: 2, estimated_subsidy: 0),
          build(:order_detail, estimated_cost: 4, estimated_subsidy: 0)])
      end

      it 'sums all totals' do
        cost.final_total.should eq(6)
      end
    end

    context 'with actual and estimated totals' do
      let(:cost) do
        OrderDetails::Cost.new([
          build(:order_detail, actual_cost: 1, actual_subsidy: 0),
          build(:order_detail, estimated_cost: 3, estimated_subsidy: 0)])
      end

      it 'sums all totals' do
        cost.final_total.should eq(4)
      end
    end

    context 'with actual and nil totals' do
      let(:cost) do
        OrderDetails::Cost.new([
          build(:order_detail, actual_cost: 1, actual_subsidy: 0),
          build(:order_detail, actual_cost: nil, actual_subsidy: nil)])
      end

      it 'sums all totals' do
        cost.final_total.should eq(1)
      end
    end
  end
end
