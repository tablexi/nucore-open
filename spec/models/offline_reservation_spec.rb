require "rails_helper"

RSpec.describe OfflineReservation do
  subject(:offline_reservation) { instrument.offline_reservations.build }
  let(:instrument) { FactoryGirl.create(:setup_instrument) }

  it { is_expected.to validate_presence_of(:admin_note) }
  it { is_expected.to validate_presence_of(:reserve_start_at) }
end
