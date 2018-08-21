# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountsHelper do
  describe "#payment_source_link_or_text" do
    subject { payment_source_link_or_text(account) }
    let(:account) { build_stubbed(:nufs_account) }
    let(:current_ability) { create(:ability, facility: current_facility) }
    let(:current_facility) { build_stubbed(:facility) }

    before(:each) do
      allow(current_ability)
        .to receive(:can?)
        .with(:edit, account)
        .and_return(allowed?)
    end

    context "when allowed to edit the account" do
      let(:allowed?) { true }
      let(:expected_path) do
        facility_account_path(current_facility, account)
      end

      it { is_expected.to include(expected_path).and include(account.to_s) }
    end

    context "when not allowed to edit the account" do
      let(:allowed?) { false }

      it { is_expected.to eq(account.to_s) }
    end
  end
end
