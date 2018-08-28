# frozen_string_literal: true

require "rails_helper"

RSpec.describe SplitAccounts::OrderDetailListTransformer, type: :service do
  let(:subaccount_1) { build_stubbed(:nufs_account) }
  let(:subaccount_2) { build_stubbed(:nufs_account) }

  let(:split_account) do
    build_stubbed(:split_account).tap do |split_account|
      split_account.splits.build percent: 50, apply_remainder: true, subaccount: subaccount_1
      split_account.splits.build percent: 50, apply_remainder: false, subaccount: subaccount_2
    end
  end

  let(:split_order_detail) do
    build_stubbed(:order_detail).tap do |order_detail|
      allow(order_detail).to receive(:account).and_return(split_account)
    end
  end

  let(:other_account) do
    build_stubbed(:setup_account)
  end

  let(:other_order_detail) do
    build_stubbed(:order_detail, account: other_account)
  end

  let(:order_details) { [split_order_detail, other_order_detail] }

  it "can initialize" do
    expect(described_class.new).to be_a(described_class)
  end

  describe "#perform" do
    let(:results) { described_class.new(order_details).perform }

    it "returns other order detail and two spoofed split order details" do
      expect(results.map(&:account)).to contain_exactly(other_account, subaccount_1, subaccount_2)
    end
  end
end
