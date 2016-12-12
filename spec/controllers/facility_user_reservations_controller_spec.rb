require "rails_helper"
require "controllers/shared_examples"

RSpec.describe FacilityUserReservationsController do
  let(:facility) { instrument.facility }
  let(:order_details) { reservations.map(&:order_detail) }
  let(:instrument) { FactoryGirl.create(:setup_instrument) }
  let!(:reservations) do
    FactoryGirl.create_list(:purchased_reservation, 3, :daily, product: instrument, user: user)
  end

  context "GET #index" do
    before(:each) do
      sign_in(user) if user.present?
      get :index,
          facility_id: facility.url_name,
          user_id: user.try(:id) || 1
    end

    context "when not logged in" do
      let(:user) { nil }

      it_behaves_like "the user must log in"
    end

    context "when logged in as a facility director" do
      let(:user) { FactoryGirl.create(:user, :facility_director, facility: facility) }

      it "generates a page of reservations", :aggregate_failures do
        expect(assigns(:user)).to eq(user)
        expect(assigns(:order_details)).to match_array(order_details)
      end
    end
  end
end
