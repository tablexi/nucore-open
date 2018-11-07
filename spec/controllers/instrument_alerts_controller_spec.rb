# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentAlertsController do
  render_views

  let(:user) { FactoryBot.create(:user, :administrator) }
  let(:instrument) { FactoryBot.create(:setup_instrument) }

  describe "POST to #create" do
    before { sign_in user }

    context "with valid parameters" do
      before do
        post :create, params: {
          facility_id: instrument.facility.url_name,
          instrument_id: instrument.url_name,
          instrument_alert: {
            note: "Only accessories A, B, and D work currently.",
          },
        }
      end

      it "creates an alert on the instrument with the specified note" do
        expect(instrument.alert).not_to be nil
      end

      it "redirects back to the instrument’s schedule path" do
        expect(response).to redirect_to facility_instrument_schedule_path(instrument.facility, instrument)
      end

      it "sets a notice in the flash" do
        expect(flash[:notice]).to be_present
      end
    end

    context "with invalid parameters" do
      before do
        post :create, params: {
          facility_id: instrument.facility.url_name,
          instrument_id: instrument.url_name,
          instrument_alert: {
            note: "",
          },
        }
      end

      it "renders the new action" do
        expect(response).to render_template("new")
      end
    end
  end

  context "DELETE to :destroy" do
    before do
      instrument.create_alert(note: "The microscope is using configuration 17 this week.")
      sign_in user
      delete :destroy, params: {
        facility_id: instrument.facility.url_name,
        instrument_id: instrument.url_name,
      }
    end

    it "redirects back to the instrument’s schedule path" do
      expect(response).to redirect_to facility_instrument_schedule_path(instrument.facility, instrument)
    end

    it "sets a notice in the flash" do
      expect(flash[:notice]).to be_present
    end
  end
end
