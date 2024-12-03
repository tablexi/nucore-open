# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Billing Tab" do
  let(:user) { create(:user, :administrator) }
  let!(:facility) { create :setup_facility }

  before do
    login_as user
  end

  describe "Reconcile Credit Card menu" do
    def refresh_account_config
      Account.config.statement_account_types.clear
      C2po.setup_account_types
    end

    it(
      "render Reconcile Credit Card if feature disabled",
      feature_setting: { credit_card_accounts: true }
    ) do
      refresh_account_config

      visit facility_transactions_path(facility)

      expect(page).to have_content("Reconcile Credit Card")
    end

    it(
      "does not render Reconcile Credit Card if feature disabled",
      feature_setting: { credit_card_accounts: false }
    ) do
      refresh_account_config

      visit facility_transactions_path(facility)

      expect(page).to_not have_content("Reconcile Credit Card")
    end
  end
end
