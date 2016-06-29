require "rails_helper"

RSpec.describe OfflineReservation do
  subject(:offline_reservation) { instrument.offline_reservations.build }
  let(:instrument) { FactoryGirl.create(:setup_instrument) }

  it { is_expected.to validate_presence_of(:admin_note) }
  it { is_expected.to validate_presence_of(:reserve_start_at) }

  describe "#as_calendar_object" do
    before(:each) do
      offline_reservation.reserve_start_at = 1.day.ago
      allow(subject).to receive(:edit_path) { "/placeholder/path" }
    end

    context "when the downtime is ongoing" do
      it "does not set end" do
        expect(offline_reservation.as_calendar_object["end"]).to be_blank
      end

      it "sets editPath" do
        expect(offline_reservation.as_calendar_object["editPath"]).to be_present
      end
    end

    context "when the downtime is over" do
      before { offline_reservation.reserve_end_at = 1.hour.ago }

      it "sets end" do
        expect(offline_reservation.as_calendar_object["end"]).to be_present
      end

      it "does not set editPath" do
        expect(offline_reservation.as_calendar_object["editPath"]).to be_blank
      end
    end
  end
end
