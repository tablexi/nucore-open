# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe UserAccountsController do
  let(:facility) { FactoryBot.create(:facility) }

  context "GET to :show" do
    before :each do
      create_users
      @authable = facility
      @method = :get
      @action = :show
      @params = { facility_id: facility.url_name, user_id: @guest.id }
    end

    it_should_allow_admin_only do
      expect(assigns(:user)).to eq(@guest)
      expect(assigns(:accounts)).to be_kind_of ActiveRecord::Relation
    end
  end
end
