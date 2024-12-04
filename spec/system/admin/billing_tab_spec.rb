# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Billing Tab" do
  let(:user) { create(:user, :administrator) }
  let!(:facility) { create :setup_facility }

  before do
    login_as user
  end

  describe "Reconcile Credit Card menu" do
    let(:link_name) { "Reconcile Credit Card" }
    it(
      "render Reconcile Credit Card if feature disabled",
      feature_setting: { reconcile_credit_cards: true }
    ) do
      visit facility_transactions_path(facility)

      expect(page).to have_content(link_name)
    end

    it(
      "does not render Reconcile Credit Card if feature disabled",
      feature_setting: { reconcile_credit_cards: false }
    ) do
      visit facility_transactions_path(facility)

      expect(page).to_not have_content(link_name)
    end
  end
end
