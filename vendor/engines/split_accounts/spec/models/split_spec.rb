# frozen_string_literal: true

require "rails_helper"
require_relative "../split_accounts_spec_helper"

RSpec.describe SplitAccounts::Split, :enable_split_accounts, type: :model do
  # TODO: remove this if/when we do factory linting
  it "has a valid factory" do
    expect(build(:split)).to be_valid
  end

  describe "validations" do
    context "when self referential" do
      let(:split) do
        build(:split).tap do |split|
          split.subaccount = split.parent_split_account
        end
      end

      it "is invalid" do
        expect(split).not_to be_valid
        expect(split.errors).to include(:subaccount)
      end
    end

    context "when percent is greater than 100" do
      let(:split) { build_stubbed(:split, percent: 101) }

      it "is invalid" do
        expect(split).not_to be_valid
        expect(split.errors).to include(:percent)
      end
    end

    context "when percent is less than 0" do
      let(:split) { build_stubbed(:split, percent: -1) }

      it "is invalid" do
        expect(split).not_to be_valid
        expect(split.errors).to include(:percent)
      end
    end
  end
end
