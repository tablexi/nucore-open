require "rails_helper"

RSpec.describe OfflineReservation do
  subject(:offline_reservation) { instrument.offline_reservations.build }
  let(:instrument) { FactoryGirl.create(:setup_instrument) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:admin_note) }
    it { is_expected.to validate_presence_of(:reserve_start_at) }

    it "allows optional designated categories" do
      is_expected
        .to validate_inclusion_of(:category)
        .in_array(%w(operator_unavailable out_of_order scheduled_maintenance))
        .allow_nil
    end
  end

  describe "#admin_removable?" do
    it { is_expected.not_to be_admin_removable }
  end

  describe "#end_at_required?" do
    it { is_expected.not_to be_end_at_required }
  end
end
