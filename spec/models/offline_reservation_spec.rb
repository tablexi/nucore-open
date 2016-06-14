require "rails_helper"

RSpec.describe OfflineReservation do
  subject(:offline_reservation) do
    instrument.offline_reservations.create(
      actual_start_at: actual_start_at,
      reserve_start_at: reserve_start_at,
    )
  end

  let(:instrument) { FactoryGirl.create(:setup_instrument) }

  describe "#new" do
    let(:reserve_start_at) { Time.current }
    let(:actual_start_at) { reserve_start_at }

    it { is_expected.to be_valid }
  end
end
