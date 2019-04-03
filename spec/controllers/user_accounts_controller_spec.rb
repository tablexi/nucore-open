# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe UserAccountsController do
  let(:facility) { FactoryBot.create(:facility) }

  before :each do
    create_users
  end

  context "GET to :show" do
    before :each do
      @authable = facility
      @method = :get
      @action = :show
      @params = { facility_id: facility.url_name, user_id: @guest.id }
    end

    it_should_allow_managers_only do
      expect(assigns(:user)).to eq(@guest)
      expect(assigns(:accounts)).to be_kind_of ActiveRecord::Relation
    end
  end

  context "PATCH to :update" do
    let(:account) { create_nufs_account_with_owner }

    before :each do
      AccountUser.grant(@guest, AccountUser::ACCOUNT_PURCHASER, account, by: @admin)
      sign_in @admin
      patch :update,
        params: {
          facility_id: facility.url_name,
          user_id: @guest.id,
          user: { accounts_attributes: {"0" => { _destroy: "1", id: @guest.accounts.first.id } } },
        }
    end

    it "updates the user’s accounts" do
      expect(@guest.accounts.reload).to be_empty
    end

    it "redirects back to the user’s accounts page" do
      expect(response).to redirect_to(facility_user_accounts_path(facility, @guest))
    end
  end
end
