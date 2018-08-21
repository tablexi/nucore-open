# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilitiesController do
  let(:admin) { FactoryBot.create(:user, :administrator) }

  describe "create" do
    before { sign_in admin }

    describe "set to true" do
      let(:params) { FactoryBot.attributes_for(:facility, accepts_po: true, accepts_cc: true) }

      it "sets the accepts parameters" do
        expect { post :create, params: { facility: params } }.to change(Facility, :count).by(1)
        facility = Facility.last
        expect(facility).to be_accepts_po
        expect(facility).to be_accepts_cc
      end
    end

    describe "set to false" do
      let(:params) { FactoryBot.attributes_for(:facility, accepts_po: false, accepts_cc: false) }

      it "sets the accepts parameters" do
        expect { post :create, params: { facility: params } }.to change(Facility, :count).by(1)
        facility = Facility.last
        expect(facility).not_to be_accepts_po
        expect(facility).not_to be_accepts_cc
      end
    end
  end
end
