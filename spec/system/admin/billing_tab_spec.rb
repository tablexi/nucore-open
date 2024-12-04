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

    it "render Reconcile Credit Card if feature disabled" do
      Account.config.creation_disabled_types.reject! { |acc| acc == CreditCardAccount.to_s }

      visit facility_transactions_path(facility)

      expect(page).to have_content(link_name)
    end

    it "does not render Reconcile Credit Card if feature disabled" do
      Account.config.creation_disabled_types.push CreditCardAccount.to_s

      visit facility_transactions_path(facility)

      expect(page).to_not have_content(link_name)
    end
  end
end
