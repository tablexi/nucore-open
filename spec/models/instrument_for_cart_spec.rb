require "rails_helper"

RSpec.describe InstrumentForCart do

  let(:facility) { FactoryBot.create(:facility) }
  let(:facility_account) { facility.facility_accounts.create(FactoryBot.attributes_for(:facility_account)) }

  let(:instrument) do
    FactoryBot.create(:instrument, facility: facility, facility_account: facility_account, no_relay: true).tap do |instrument|
      FactoryBot.create(:instrument_price_policy, product: instrument, price_group: @nupg)
    end
  end

  let(:user) { FactoryBot.create(:user) }

  let(:instrument_for_cart) { InstrumentForCart.new(instrument, InstrumentsController.new) }

  context "#purchasable_by?" do

    context "when the instrument does not have any schedule rules" do
      it "returns false" do
        expect(instrument_for_cart.purchasable_by?(user, user)).to be false
      end

      it "sets error_message explaining that a schedule is unavailable" do
        instrument_for_cart.purchasable_by?(user, user)
        expect(instrument_for_cart.error_message).to match(/A schedule for this instrument is currently unavailable/)
      end
    end

  end

end
