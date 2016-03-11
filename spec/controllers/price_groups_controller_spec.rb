require "rails_helper"
require "controller_spec_helper"

RSpec.describe PriceGroupsController do
  render_views

  let(:facility) { create(:facility) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility # Required to be set for controller_spec_helper
    @params = { facility_id: facility.url_name }
  end

  describe "GET #index" do
    let!(:price_groups) { create_list(:price_group, 3, facility: facility) }

    before(:each) do
      @method = :get
      @action = :index
    end

    it_should_allow_managers_only do
      expect(assigns(:price_groups)).to be_kind_of(Array).and eq(facility.price_groups)
    end
  end

  describe "GET #new" do
    before(:each) do
      @method = :get
      @action = :new
    end

    it_should_allow_managers_only do
      expect(assigns(:price_group)).to be_kind_of(PriceGroup).and be_new_record
      is_expected.to render_template("new")
    end
  end

  describe "POST #create" do
    before(:each) do
      @method = :post
      @action = :create
      @params.merge!(price_group: attributes_for(:price_group, facility_id: facility.id))
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:price_group)).to be_kind_of(PriceGroup).and be_persisted
      expect(flash[:notice]).to include("successfully created")
      assert_redirected_to [facility, assigns(:price_group)]
    end
  end

  context "with a price group id parameter" do
    let(:price_group) { create(:price_group, facility: facility) }

    before { @params.merge!(id: price_group.id) }

    describe "GET #show" do
      before(:each) do
        @method = :get
        @action = :show
      end

      it_should_allow_managers_only :redirect do
        expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
        is_expected.to redirect_to(accounts_facility_price_group_path(facility, price_group))
      end
    end

    describe "GET #users" do
      before(:each) do
        @method = :get
        @action = :users
      end

      context "when user-based price groups are enabled", feature_setting: { user_based_price_groups: true } do
        it_should_allow_managers_only do
          expect(assigns(:user_members)).to be_kind_of(ActiveRecord::Relation)
          expect(assigns(:tab)).to eq(:users)
          is_expected.to render_template("show")
        end
      end

      context "when user-based price groups are disabled", feature_setting: { user_based_price_groups: false } do
        before(:each) do
          maybe_grant_always_sign_in(user)
          do_request
        end

        context "for admins" do
          let(:user) { :admin }
          it { expect(response.code).to eq("404") }
        end

        context "for directors" do
          let(:user) { :director }
          it { expect(response.code).to eq("404") }
        end

        context "for senior staff" do
          let(:user) { :senior_staff }
          it { expect(response.code).to eq("403") }
        end

        context "for staff" do
          let(:user) { :staff }
          it { expect(response.code).to eq("403") }
        end

        context "for guests" do
          let(:user) { :staff }
          it { expect(response.code).to eq("403") }
        end
      end
    end

    describe "GET #accounts" do
      before(:each) do
        @method = :get
        @action = :accounts
      end

      it_should_allow_managers_only do
        expect(assigns(:account_members)).to be_kind_of(ActiveRecord::Relation)
        expect(assigns(:tab)).to eq(:accounts)
        is_expected.to render_template("show")
      end
    end

    describe "GET #edit" do
      before(:each) do
        @method = :get
        @action = :edit
      end

      it_should_allow_managers_only do
        expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
        is_expected.to render_template("edit")
      end
    end

    describe "PUT #update" do
      before(:each) do
        @method = :put
        @action = :update
        @params.merge!(price_group: attributes_for(:price_group, facility_id: facility.id))
      end

      it_should_allow_managers_only :redirect do
        expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
        expect(flash[:notice]).to include("successfully updated")
        is_expected.to redirect_to([facility, price_group])
      end
    end

    describe "DELETE #destroy" do
      before(:each) do
        @method = :delete
        @action = :destroy
      end

      it_should_allow_managers_only :redirect do
        expect(assigns(:price_group)).to be_kind_of(PriceGroup).and eq(price_group)
        should_be_destroyed price_group
        is_expected.to redirect_to(facility_price_groups_url)
      end
    end
  end
end
