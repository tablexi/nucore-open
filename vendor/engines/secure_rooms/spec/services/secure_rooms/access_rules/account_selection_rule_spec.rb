# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessRules::AccountSelectionRule, type: :service do
  let(:rule) do
    described_class.new(
      card_user,
      card_reader,
      requested_account_id: account_identifier,
    )
  end
  let(:card_user) { build :user }
  let(:card_reader) { build :card_reader }
  let(:account_identifier) { nil }

  subject(:result) { rule.call }

  context "no accounts exist" do
    it { is_expected.to have_result_code(:deny) }
  end

  context "one account exists" do
    let(:account) { create(:account, :with_account_owner, owner: card_user) }

    before do
      allow_any_instance_of(User).to receive(:accounts_for_product).and_return([account])
    end

    context "wihtout a selection" do
      let(:account_identifier) { nil }

      it { is_expected.to have_result_code(:pending) }
    end
  end

  context "accounts exist" do
    let(:accounts) { create_list(:account, 3, :with_account_owner, owner: card_user) }

    before do
      allow_any_instance_of(User).to receive(:accounts_for_product).and_return(accounts)
    end

    context "selected account was found" do
      let(:account_identifier) { accounts.first.id.to_s }

      it { is_expected.to have_result_code(:grant) }
      it "stores the selected account" do
        expect(result.selected_account).to eq accounts.first
      end
    end

    context "selected account is empty but accounts exist" do
      it { is_expected.to have_result_code(:pending) }
    end
  end
end
