# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentForCart do

  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:instrument) { FactoryBot.create(:instrument, facility: facility, no_relay: true) }
  let(:user) { FactoryBot.create(:user) }
  let(:instrument_for_cart) { InstrumentForCart.new(instrument) }

  context "#purchasable_by?" do

    context "when the acting user is not present" do
      it "sets error_path to the sign-in page" do
        instrument_for_cart.purchasable_by?(nil, user)
        expect(instrument_for_cart.error_path).to eq Rails.application.routes.url_helpers.new_user_session_path
      end
    end

    context "when the instrument does not have any schedule rules" do
      it "returns false" do
        expect(instrument_for_cart.purchasable_by?(user, user)).to be false
      end

      it "sets error_message explaining that a schedule is unavailable" do
        instrument_for_cart.purchasable_by?(user, user)
        expect(instrument_for_cart.error_message).to match(/A schedule for this instrument is currently unavailable/)
      end

      it "sets error_path to the facility’s page" do
        instrument_for_cart.purchasable_by?(user, user)
        expect(instrument_for_cart.error_path).to eq Rails.application.routes.url_helpers.facility_path(facility)
      end
    end

  end

end
