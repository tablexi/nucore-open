require "rails_helper"
require "controller_spec_helper" # for the #facility_operators helper method

def facility_operator_roles # Translates helper roles to User factory traits
  facility_operators.map do |role|
    case role
    when :admin
      :facility_administrator
    when :senior_staff, :staff
      role
    else
      "facility_#{role}".to_sym
    end
  end
end

RSpec.describe Projects::ProjectsController, type: :controller do
  let(:facility) { FactoryGirl.create(:facility) }

  describe "GET #index" do
    def do_request
      get :index, facility_id: facility.url_name
    end

    describe "when not logged in" do
      before { do_request }

      it { is_expected.to redirect_to new_user_session_path }
    end

    describe "when logged in" do
      shared_examples_for "it allows index views" do |role|
        let(:user) { FactoryGirl.create(:user, role, facility: facility) }

        before(:each) do
          sign_in user
          do_request
        end

        it "shows the index view" do
          expect(response.code).to eq("200")
          expect(assigns(:projects)).to match_array(facility.projects)
        end
      end

      facility_operator_roles.each do |role|
        context "as #{role}" do
          it_behaves_like "it allows index views", role
        end
      end
    end
  end

  describe "GET #new" do
    def do_request
      get :new, facility_id: facility.url_name
    end

    describe "when not logged in" do
      before { do_request }

      it { is_expected.to redirect_to new_user_session_path }
    end

    describe "when logged in" do
      shared_examples_for "it allows new views" do |role|
        let(:user) { FactoryGirl.create(:user, role, facility: facility) }

        before(:each) do
          sign_in user
          do_request
        end

        it "shows the new view" do
          expect(response.code).to eq("200")
          expect(assigns(:project)).to be_kind_of(Projects::Project).and be_new_record
        end
      end

      facility_operator_roles.each do |role|
        context "as #{role}" do
          it_behaves_like "it allows new views", role
        end
      end
    end
  end

  describe "POST #create" do
    def do_request
      post :create,
           facility_id: facility.url_name,
           projects_project: { name: name, description: description }
    end

    let(:name) { "Project Name" }
    let(:description) { "A project description" }

    describe "when not logged in" do
      before { do_request }

      it { is_expected.to redirect_to new_user_session_path }
    end

    describe "when logged in" do
      shared_examples_for "it allows project creation" do |role|
        let(:created_project) { Projects::Project.last }
        let(:user) { FactoryGirl.create(:user, role, facility: facility) }

        before(:each) do
          sign_in user
          do_request
        end

        it "creates a new project" do
          is_expected.to redirect_to facility_projects_path(facility)
          expect(created_project.name).to eq(name)
          expect(created_project.description).to eq(description)
        end
      end

      facility_operator_roles.each do |role|
        context "as #{role}" do
          it_behaves_like "it allows project creation", role
        end
      end
    end
  end
end
