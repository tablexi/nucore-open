require "rails_helper"
require_relative "../split_accounts_spec_helper"

RSpec.describe SplitAccounts::SplitAccount, :enable_split_accounts, type: :model do

  it "is an account type" do
    expect(described_class.new).to be_an(Account)
  end

  # TODO: remove this if/when we do factory linting
  it "has a valid factory" do
    expect(build(:split_account)).to be_valid
  end

  describe "validations" do

    let(:subaccount_1) { build_stubbed(:setup_account) }
    let(:subaccount_2) { build_stubbed(:setup_account) }

    context "when only one split" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 100, extra_penny: true, parent_split_account: split_account)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        expect(split_account.errors[:splits]).to include(I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.more_than_one_split"))
      end
    end

    context "when splits total 100 and one split has extra_penny" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 50, extra_penny: false, parent_split_account: split_account, subaccount: subaccount_2)
        end
      end

      it "is valid" do
        expect(split_account).to be_valid
      end
    end

    context "when splits do not total 100 and one split has extra_penny" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 49.99, extra_penny: false, parent_split_account: split_account, subaccount: subaccount_2)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        message = I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.percent_total")
        expect(split_account.errors[:splits]).to include(message)
      end
    end

    context "when splits total 100 and no splits have extra_penny" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: false, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 50, extra_penny: false, parent_split_account: split_account, subaccount: subaccount_2)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        message = I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.only_one_extra_penny")
        expect(split_account.errors[:splits]).to include(message)
      end
    end

    context "when splits total 100 and multiple splits have extra_penny" do
      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account, subaccount: subaccount_2)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        message = I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.only_one_extra_penny")
        expect(split_account.errors[:splits]).to include(message)
      end
    end

    context "when splits share one or more subaccount" do

      let(:split_account) do
        build(:split_account, without_splits: true).tap do |split_account|
          split_account.splits << build(:split, percent: 50, extra_penny: true, parent_split_account: split_account, subaccount: subaccount_1)
          split_account.splits << build(:split, percent: 50, extra_penny: false, parent_split_account: split_account, subaccount: subaccount_1)
        end
      end

      it "is invalid" do
        expect(split_account).not_to be_valid
        message = I18n.t("activerecord.errors.models.split_accounts/split_account.attributes.splits.duplicate_subaccounts")
        expect(split_account.errors[:splits]).to include(message)
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
      expect(split_account.subaccounts).to contain_exactly(*split_account.splits.map(&:subaccount))
    end
  end

end
