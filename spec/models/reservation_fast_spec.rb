# frozen_string_literal: true

require "rails_helper"

# No specs in this file should touch the database
RSpec.describe Reservation do
  describe "ongoing?" do
    context "complete" do
      before { allow(reservation).to receive(:complete?).and_return true }
      context "with actuals" do
        subject(:reservation) { build_stubbed :reservation, actual_start_at: 1.hour.ago, actual_end_at: 30.minutes.ago }
        it { is_expected.not_to be_ongoing }
      end

      context "missing actual end" do
        subject(:reservation) { build_stubbed :reservation, actual_start_at: 1.hour.ago }
        it { is_expected.not_to be_ongoing }
      end
    end

    context "incomplete" do
      before { allow(reservation).to receive(:complete?).and_return false }
      context "has not started" do
        subject(:reservation) { build_stubbed :reservation, actual_start_at: nil, actual_end_at: nil }
        it { is_expected.not_to be_ongoing }
      end

      context "it has started and not ended" do
        subject(:reservation) { build_stubbed :reservation, actual_start_at: 1.hour.ago, actual_end_at: nil }
        it { is_expected.to be_ongoing }
      end
    end
  end
end
