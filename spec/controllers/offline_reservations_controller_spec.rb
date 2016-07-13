require "rails_helper"

RSpec.describe OfflineReservationsController do
  let(:admin) { FactoryGirl.create(:user, :administrator) }
  let(:instrument) { FactoryGirl.create(:setup_instrument) }

  before { sign_in admin }

  describe "POST #create" do
    let(:params) do
      {
        facility_id: instrument.facility.url_name,
        instrument_id: instrument.url_name,
        offline_reservation: { admin_note: "The instrument is down" },
      }
    end

    context "when an ongoing reservation exists for the instrument" do
      let!(:reservation) do
        FactoryGirl.create(:setup_reservation, :running, product: instrument)
      end

      it "becomes a problem reservation" do
        expect { post :create, params }
          .to change { reservation.reload.problem? }
          .from(false)
          .to(true)
      end
    end
  end
end
