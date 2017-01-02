require "rails_helper"
require "controllers/shared_examples"

RSpec.describe FacilityUserReservationsController do
  let(:facility) { instrument.facility }
  let(:facility_director) { FactoryGirl.create(:user, :facility_director, facility: facility) }
  let(:instrument) { FactoryGirl.create(:setup_instrument, min_cancel_hours: 9999) }
  let(:price_policies) { instrument.price_policies }
  let(:user) { FactoryGirl.create(:user) }

  context "GET #index" do
    let(:order_details) { reservations.map(&:order_detail) }
    let!(:reservations) do
      FactoryGirl.create_list(:purchased_reservation, 3, :daily, product: instrument, user: user)
    end

    context "when not logged in" do
      before { get :index, facility_id: facility.url_name, user_id: user.id }

      it_behaves_like "the user must log in"
    end

    context "when logged in as a facility director" do
      before(:each) do
        sign_in(facility_director)
        get :index, facility_id: facility.url_name, user_id: user.id
      end

      it "generates a page of reservations", :aggregate_failures do
        expect(assigns(:user)).to eq(user)
        expect(assigns(:order_details)).to match_array(order_details)
      end
    end
  end

  context "PUT #cancel" do
    let(:order_detail) { reservation.order_detail }
    let!(:reservation) do
      FactoryGirl.create(:purchased_reservation, product: instrument, user: user)
    end

    shared_examples_for "it can cancel the reservation" do
      context "when a cancellation fee applies" do
        before(:each) do
          sign_in(operator)
          price_policies.update_all(cancellation_cost: 12)

          put :cancel,
              facility_id: facility.url_name,
              user_id: user.id,
              id: order_detail.id
        end

        it "cancels the reservation with fee, considering the order 'complete'", :aggregate_failures do
          expect(response)
            .to redirect_to(facility_user_reservations_path(facility, user))
          expect(order_detail.reload).to be_complete
          expect(order_detail.actual_cost).to eq(12)
        end
      end
    end

    context "as a facility_director" do
      let(:operator) { facility_director }
      it_behaves_like "it can cancel the reservation"
    end
  end
end
