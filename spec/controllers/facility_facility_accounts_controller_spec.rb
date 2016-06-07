require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityFacilityAccountsController, if: SettingsHelper.feature_on?(:recharge_accounts) do
  render_views

  before(:all) { create_users }

  let(:facility) { @authable = create(:facility) }
  let!(:facility_account) { create(:facility_account, facility: facility, created_by: @admin.id) }

  before { @params = { facility_id: facility.url_name } }

  describe "GET #index" do
    before(:each) do
      @method = :get
      @action = :index
    end

    it_should_allow_managers_only do
      expect(assigns(:accounts)).to all be_kind_of(FacilityAccount)
      expect(assigns(:accounts).size).to eq(1)
      expect(assigns(:accounts).first).to eq(facility_account)
      is_expected.to render_template "index"
    end
  end

  describe "GET #new" do
    before(:each) do
      @method = :get
      @action = :new
    end

    it_should_allow_managers_only do
      expect(assigns(:facility_account))
        .to be_kind_of(FacilityAccount).and be_new_record
      is_expected.to render_template "new"
    end
  end

  describe "PUT #update" do
    before(:each) do
      @method = :put
      @action = :update
      @params.merge!(
        id: facility_account.id,
        facility_account: attributes_for(:facility_account),
      )
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:facility_account))
        .to be_kind_of(FacilityAccount).and eq(facility_account)
      is_expected.to set_flash
      is_expected.to redirect_to(facility_facility_accounts_path)
    end
  end

  describe "POST #create" do
    before(:each) do
      @method = :post
      @action = :create
      @params.merge!(facility_account: attributes_for(:facility_account))
    end

    it_should_allow_managers_only :redirect do |user|
      expect(assigns(:facility_account)).to be_kind_of(FacilityAccount)
      expect(assigns(:facility_account).created_by).to eq(user.id)
      is_expected.to set_flash
      is_expected.to redirect_to(facility_facility_accounts_path)
    end
  end

  describe "GET #edit" do
    before(:each) do
      @method = :get
      @action = :edit
      @params.merge!(id: facility_account.id)
    end

    it_should_allow_managers_only do
      expect(assigns(:facility_account))
        .to be_kind_of(FacilityAccount).and eq(facility_account)

      assigns(:facility_account).account_number_parts.to_h.each do |key, value|
        expect(response.body).to match(/\[account_number_parts\]\[#{key}\].+value="#{value}"/)
      end

      is_expected.to render_template "edit"
    end
  end
end
