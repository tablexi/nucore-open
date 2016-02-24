require "rails_helper"
require_relative "../../engine_helper"

RSpec.describe SplitAccounts::Converters::OrderDetailToJournalRowAttributes, type: :service, split_accounts: true do

  let(:converter) do
    described_class.new(journal, order_detail, total: total, splits: splits)
  end

  let(:journal) { build_stubbed(:journal) }
  let(:order_detail) { build_stubbed(:order_detail) }
  let(:total) { BigDecimal("19.99") }
  let(:splits) { build_stubbed_list(:split, 1) }

  describe "initialize" do

    it "sets journal" do
      expect(converter.journal).to eq(journal)
    end

    it "sets order_detail" do
      expect(converter.order_detail).to eq(order_detail)
    end

    it "sets total" do
      expect(converter.total).to eq(total)
    end

    it "sets splits" do
      expect(converter.splits).to eq(splits)
    end

  end

  describe "#build_split_amount" do
    let(:total) { BigDecimal("19.99") }
    let(:percent) { 33.33 }
    let(:floored_amount) { 6.66 }
    let(:split) { build_stubbed(:split, percent: percent) }
    let(:returned) { converter.build_split_amount(split) }

    it "returns a SplitAmount instance" do
      expect(returned).to be_a(described_class::SplitAmount)
    end

    it "sets split" do
      expect(returned.split).to eq(split)
    end

    it "sets floored amount" do
      expect(returned.amount).to eq(floored_amount)
    end
  end

  context "with a three way $19.99 split that has a remainder of $0.01" do
    let(:total) { BigDecimal("19.99") }
    let(:remainder) { BigDecimal("0.01") }
    let(:split_amounts) do
      [
        converter.build_split_amount(build_stubbed(:split, percent: 33.33, extra_penny: false)),
        converter.build_split_amount(build_stubbed(:split, percent: 33.33, extra_penny: true)),
        converter.build_split_amount(build_stubbed(:split, percent: 33.34, extra_penny: false)),
      ]
    end
    let(:before_remainder_applied) { split_amounts.second }
    let(:after_remainder_applied) { converter.apply_remainder(split_amounts).second }

    describe "#apply_remainder" do

      it "starts with a floored split amount" do
        expect(before_remainder_applied.amount).to eq(6.66)
      end

      it "adds the remainder to the correct split" do
        expect(after_remainder_applied.amount).to eq(6.67)
      end
    end

    describe "#floored_total" do
      it "sums up the floored amount without the remainder applied" do
        expect(converter.floored_total(split_amounts)).to eq(19.98)
      end
    end
  end

  describe "#floored_amount" do
    let(:total) { BigDecimal("19.99") }

    it "returns 0 if percent is 0" do
      expect(converter.floored_amount(0)).to eq(0)
    end

    it "returns floored value" do
      expect(converter.floored_amount(50)).to eq(9.99)
    end
  end
end
