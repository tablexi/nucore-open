require 'spec_helper'

# No specs in this file should touch the database
describe Reservation do
  describe 'ongoing?' do
    context 'complete' do
      before { allow(reservation).to receive(:complete?).and_return true }
      context 'with actuals' do
        subject(:reservation) { build_stubbed :reservation, actual_start_at: 1.hour.ago, actual_end_at: 30.minutes.ago }
        it { should_not be_ongoing }
      end

      context 'missing actual end' do
        subject(:reservation) { build_stubbed :reservation, actual_start_at: 1.hour.ago }
        it { should_not be_ongoing }
      end
    end

    context 'incomplete' do
      before { allow(reservation).to receive(:complete?).and_return false }
      context 'has not started' do
        subject(:reservation) { build_stubbed :reservation, actual_start_at: nil, actual_end_at: nil }
        it { should_not be_ongoing }
      end

      context 'it has started and not ended' do
        subject(:reservation) { build_stubbed :reservation, actual_start_at: 1.hour.ago, actual_end_at: nil }
        it { should be_ongoing }
      end
    end
  end
end
