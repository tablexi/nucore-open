# frozen_string_literal: true

require "rails_helper"

RSpec.describe CancellationFeeCalculator do
  let(:calculator) { described_class.new(reservation) }

  describe "#fee" do
    subject { calculator.fee }

    context "when there is no reservation" do
      let(:reservation) { nil }
      it { is_expected.to eq(0) }
    end

    let(:reservation) { FactoryBot.create(:purchased_reservation, product: instrument) }
    let(:instrument) { FactoryBot.create(:setup_instrument, min_cancel_hours: 9999) }

    context "when there is no cancellation_cost" do
      it { is_expected.to eq(0) }
    end

    context "when there is a cancellation_cost" do
      before { instrument.price_policies.update_all(cancellation_cost: 45.75) }
      it { is_expected.to eq(45.75) }
    end

  end
end
