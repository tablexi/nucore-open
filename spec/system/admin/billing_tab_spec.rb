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

    around do |example|
      creation_disabled_types_orig = Account.config.creation_disabled_types.dup

      example.run

      Account.config.instance_eval do
        @creation_disabled_types = creation_disabled_types_orig
      end
    end

    it "render Reconcile Credit Card if its creation is enabled" do
      Account.config.creation_disabled_types.reject! { |acc| acc == CreditCardAccount.to_s }

      visit facility_transactions_path(facility)

      expect(page).to have_content(link_name)
    end

    it "does not render Reconcile Credit Card if its creation is disabled" do
      Account.config.creation_disabled_types.push CreditCardAccount.to_s

      visit facility_transactions_path(facility)

      expect(page).to_not have_content(link_name)
    end
  end
end
