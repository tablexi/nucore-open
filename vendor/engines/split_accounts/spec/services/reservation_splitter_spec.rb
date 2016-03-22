require "rails_helper"

RSpec.describe SplitAccounts::ReservationSplitter do
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
      order_detail.created_by = 1 # for testing dup

      order_detail.quantity = 3
      order_detail.actual_cost = BigDecimal("9.99")
      order_detail.actual_subsidy = BigDecimal("19.99")
      order_detail.estimated_cost = BigDecimal("29.99")
      order_detail.estimated_subsidy = BigDecimal("39.99")
      order_detail.account = split_account
    end
  end

  let(:reservation) { build_stubbed(:reservation, duration_mins: 25, actual_duration_mins: 35, order_detail: order_detail) }
  let(:results) { described_class.new(reservation).split }

  it "splits the reservation minutes" do
    expect(results.map(&:duration_mins)).to contain_exactly(12.5, 12.5)
  end

  it "splits the actual minutes" do
    expect(results.map(&:actual_duration_mins)).to contain_exactly(17.5, 17.5)
  end

  it "splits the order detail's accounts" do
    expect(results.map { |res| res.order_detail.account }).to eq([subaccount_1, subaccount_2])
  end

  it "splits to order details costs" do
    expect(results.map { |res| res.order_detail.actual_cost }).to eq([5, 4.99])
  end
end
