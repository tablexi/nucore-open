# frozen_string_literal: true

require "rails_helper"

RSpec.describe OfflineReservationsController do
  let(:administrator) { FactoryBot.create(:user, :administrator) }
  let(:facility) { instrument.facility }
  let(:instrument) { FactoryBot.create(:setup_instrument) }

  describe "POST #create" do
    before { sign_in administrator }

    let(:params) do
      {
        facility_id: instrument.facility.url_name,
        instrument_id: instrument.url_name,
        offline_reservation: {
          admin_note: "The instrument is down",
          category: "out_of_order",
        },
      }
    end

    it "sets created_by" do
      post :create, params: params

      expect(assigns[:reservation].created_by).to eq administrator
    end

    context "when an ongoing reservation exists for the instrument" do
      let!(:reservation) do
        FactoryBot.create(:setup_reservation, :running, product: instrument)
      end

      it "becomes a problem reservation" do
        expect { post :create, params: params }
          .to change { reservation.order_detail.reload.problem? }
          .from(false)
          .to(true)
      end
    end
  end

  describe "PUT #bring_online" do
    let(:instrument) { FactoryBot.create(:setup_instrument, :offline) }
    let(:params) do
      {
        facility_id: instrument.facility.url_name,
        instrument_id: instrument.url_name,
      }
    end

    shared_examples_for "it brings the instrument online" do |role|
      let(:user) { FactoryBot.create(:user, role, facility: facility) }
      before { sign_in user }

      it "brings the instrument online", :aggregate_failures do
        expect { put :bring_online, params: params }
          .to change { instrument.reload.online? }
          .from(false)
          .to(true)
        expect(response).to redirect_to(facility_instrument_schedule_path)
        expect(flash[:notice]).to include("back online")
        expect(flash[:error]).to be_blank
      end
    end

    context "as a facility administrator" do
      it_behaves_like "it brings the instrument online", :facility_administrator
    end

    context "as a facility director" do
      it_behaves_like "it brings the instrument online", :facility_director
    end

    context "as senior staff" do
      it_behaves_like "it brings the instrument online", :senior_staff
    end

    context "as staff" do
      let(:staff) { FactoryBot.create(:user, :staff, facility: facility) }

      before { sign_in staff }

      it "may not bring the instrument online", :aggregate_failures do
        expect { put :bring_online, params: params }
          .not_to change { instrument.reload.online? }
        expect(response.code).to eq("403")
      end
    end
  end
end
