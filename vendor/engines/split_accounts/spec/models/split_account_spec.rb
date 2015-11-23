require "rails_helper"
require_relative "../engine_helper"

RSpec.describe SplitAccounts::SplitAccount, type: :model, split_accounts: true do

  it "is an account type" do
    expect(described_class.new).to be_an(Account)
  end

  # TODO: remove this if/when we do factory linting
  it "has a valid factory" do
    expect(build(:split_account)).to be_valid
  end

  describe "validations" do

    context "when splits total 100 and one split has extra_penny" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account)
          split_account.splits << build(:split, percent: 50, extra_penny: false, parent_split_account: split_account)
        end
      end

      it "is valid" do
        expect(split_account).to be_valid
      end
    end

    context "when splits do not total 100 and one split has extra_penny" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account)
          split_account.splits << build(:split, percent: 49.99, extra_penny: false, parent_split_account: split_account)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        expect(split_account.errors).to include(:splits)
      end
    end

    context "when splits total 100 and no splits have extra_penny" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: false, parent_split_account: split_account)
          split_account.splits << build(:split, percent: 50, extra_penny: false, parent_split_account: split_account)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        expect(split_account.errors).to include(:splits)
      end
    end

    context "when splits total 100 and multiple splits have extra_penny" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account)
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        expect(split_account.errors).to include(:splits)
      end
    end
  end

  describe "#percent_total" do
    let(:split_account) do
      described_class.new.tap do |split_account|
        split_account.splits.build(percent: 25)
        split_account.splits.build(percent: 50.1)
      end
    end

    let(:sum) { BigDecimal.new("75.1") }

    it "is a BigDecimal" do
      expect(split_account.percent_total).to be_a(BigDecimal)
    end

    it "sums the percent of each split" do
      expect(split_account.percent_total).to eq(sum)
    end
  end

  describe "#extra_penny_count" do
    let(:split_account) do
      described_class.new.tap do |split_account|
        split_account.splits.build(extra_penny: true)
        split_account.splits.build(extra_penny: true)
        split_account.splits.build(extra_penny: false)
      end
    end

    it "counts splits with extra penny" do
      expect(split_account.extra_penny_count).to eq(2)
    end
  end

  describe "has_many subaccounts" do
    let(:split_account) { create(:split_account) }

    it "returns subaccounts" do
      expect(split_account.subaccounts).to contain_exactly(split_account.splits.first.subaccount)
    end
  end

end
