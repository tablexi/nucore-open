# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityUsersController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:facility)
    @params = { facility_id: @authable.url_name }
  end

  context "index" do

    before :each do
      @method = :get
      @action = :index
      grant_role(@staff)
    end

    it_should_allow_managers_only do |user|
      expect(assigns(:users).size).to be >= 1
      expect(assigns(:users)).to include @staff
      expect(assigns(:users)).to include user unless user == @admin
    end

  end

  context "destroy" do

    before :each do
      @method = :delete
      @action = :destroy
      grant_role(@staff)
      @params.merge!(id: @staff.id)
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:user)).to be_kind_of User
      expect(assigns(:user)).to eq(@staff)
      expect(@staff.reload.facility_user_roles(@authable)).to be_empty
      assert_redirected_to facility_facility_users_url
    end

  end

  context "search" do

    before :each do
      @method = :get
      @action = :search
    end

    it_should_allow_managers_only { is_expected.to render_template("search") }

  end

  context "map_user" do

    before :each do
      @method = :post
      @action = :map_user
      @params.merge!(facility_user_id: @staff.id, user_role: { role: UserRole::FACILITY_STAFF })
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:user)).to be_kind_of User
      expect(assigns(:user)).to eq(@staff)
      expect(assigns(:user_role)).to be_kind_of UserRole
      expect(assigns(:user_role).user).to eq(@staff)
      expect(assigns(:user_role).facility).to eq(@authable)
      assert_redirected_to facility_facility_users_url
    end

  end

end
