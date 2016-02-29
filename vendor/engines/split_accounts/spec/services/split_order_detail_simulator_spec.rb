require "rails_helper"

RSpec.describe SplitAccounts::SplitOrderDetailSimulator, type: :service do

  let(:subaccount_1) { build_stubbed(:nufs_account) }
  let(:subaccount_2) { build_stubbed(:nufs_account) }

  let(:split_account) do
    build_stubbed(:split_account).tap do |split_account|
      split_account.splits.build percent: 50, extra_penny: true, subaccount: subaccount_1
      split_account.splits.build percent: 50, extra_penny: false, subaccount: subaccount_2
    end
  end

  let(:order_detail) do
    build_stubbed(:order_detail).tap do |order_detail|
      order_detail.created_by = 1 # used to test clone

      order_detail.quantity = 3
      order_detail.actual_cost = BigDecimal("9.99")
      order_detail.actual_subsidy = BigDecimal("19.99")
      order_detail.estimated_cost = BigDecimal("29.99")
      order_detail.estimated_subsidy = BigDecimal("39.99")

      allow(order_detail).to receive(:account).and_return(split_account)
    end
  end

  it "can be initialized" do
    expect(described_class.new(order_detail))
  end

  describe "#simulated_order_details" do
    let(:results) { described_class.new(order_detail).simulated_order_details }

    it "returns correct number of simulated order details" do
      expect(results.size).to eq(split_account.splits.size)
    end

    it "clones order details" do
      results.each do |result|
        expect(result.created_by).to eq(order_detail.created_by)
      end
    end

    it "simulates account" do
      expect(results.map(&:account)).to contain_exactly(subaccount_1, subaccount_2)
    end

    it "splits simulated quantity" do
      expect(results.map(&:quantity)).to contain_exactly(1.5, 1.5)
    end

    it "splits simulated actual_cost" do
      expect(results.map(&:actual_cost)).to contain_exactly(5.0, 4.99)
    end

    it "splits simulated actual_subsidy" do
      expect(results.map(&:actual_subsidy)).to contain_exactly(10.0, 9.99)
    end

    it "splits simulated estimated_cost" do
      expect(results.map(&:estimated_cost)).to contain_exactly(15.0, 14.99)
    end

    it "splits simulated estimated_subsidy" do
      expect(results.map(&:estimated_subsidy)).to contain_exactly(20.0, 19.99)
    end
  end

end
