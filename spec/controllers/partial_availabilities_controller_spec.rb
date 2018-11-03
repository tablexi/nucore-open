# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartialAvailabilitiesController do
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
          partial_availability: {
            note: "Only accessories A, B, and D work currently.",
          },
        }
      end

      it "creates a partial_availability on the instrument with the specified note" do
        expect(instrument.partial_availability).not_to be nil
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
          partial_availability: {
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
      instrument.create_partial_availability(note: "Only the microscope’s left mirror works.")
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
