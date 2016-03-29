require "rails_helper"

RSpec.describe Projects::ProjectsController, type: :controller do
  let(:facility) { create(:facility) }

  let(:administrator) { create(:user, :administrator) }
  let(:facility_administrator) { create(:user, :facility_administrator, facility: facility) }
  let(:facility_director) { create(:user, :facility_director, facility: facility) }
  let(:senior_staff) { create(:user, :senior_staff, facility: facility) }
  let(:staff) { create(:user, :staff, facility: facility) }

  describe "GET #index" do
    def do_request
      get :index, facility_id: facility.url_name
    end

    describe "when not logged in" do
      before { do_request }

      it { is_expected.to redirect_to new_user_session_path }
    end

    describe "when logged in" do
      shared_examples_for "it allows index views" do
        before(:each) do
          sign_in user
          do_request
        end

        it "shows the index view", :aggregate_failures do
          expect(response.code).to eq("200")
          expect(assigns(:projects)).to match_array(facility.projects)
        end
      end

      context "as a facility_administrator" do
        let(:user) { facility_administrator }
        it_behaves_like "it allows index views"
      end

      context "as a facility_director" do
        let(:user) { facility_director }
        it_behaves_like "it allows index views"
      end

      context "as facility senior_staff" do
        let(:user) { senior_staff }
        it_behaves_like "it allows index views"
      end

      context "as facility staff" do
        let(:user) { staff }
        it_behaves_like "it allows index views"
      end
    end
  end

  describe "GET #new" do
  end

  describe "POST #create" do
  end
end
