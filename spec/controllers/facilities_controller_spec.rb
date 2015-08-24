require 'spec_helper'
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

describe FacilitiesController do
  render_views

  it "should route" do
    { :get => "/facilities" }.should route_to(:controller => 'facilities', :action => 'index')
    { :get => "/facilities/url_name" }.should route_to(:controller => 'facilities', :action => 'show', :id => 'url_name')
    { :get => "/facilities/url_name/manage" }.should route_to(:controller => 'facilities', :action => 'manage', :id => 'url_name')
  end

  before(:all) { create_users }

  let(:facility) { FactoryGirl.create(:facility) }
  let(:facility_account) { FactoryGirl.create(:facility_account, :facility => facility) }

  before(:each) do
    @authable = facility
  end


  context "new" do

    before(:each) do
      @method=:get
      @action=:new
    end

    it_should_require_login

    it_should_deny :director

    it_should_allow :admin do
      @controller.should_receive(:init_current_facility).never
      do_request
      response.should be_success
      response.should render_template('facilities/new')
    end

  end


  context "create" do

    before(:each) do
      @method=:post
      @action=:create
      @params={
        :facility => {
          :name => "A New Facility", :abbreviation => "anf", :description => "A boring description",
          :is_active => 1, :url_name => 'anf', :short_description => 'A short boring desc'
        }
      }
    end

    it_should_require_login

    it_should_deny_all [ :guest, :director ]

    it_should_allow :admin do
      assigns[:facility].should be_valid
      response.should redirect_to "/facilities/anf/manage"
    end

  end


  context "index" do

    before(:each) do
      @method=:get
      @action=:index
    end

    it_should_allow_all [ :admin, :guest ] do
      assigns[:facilities].should == [@authable]
      response.should be_success
      response.should render_template('facilities/index')
    end

  end


  context "manage" do

    before(:each) do
      @method=:get
      @action=:manage
      @params={ :facility_id => @authable.url_name, :id => @authable.url_name }
    end

    it_should_require_login

    it_should_deny :guest

    it_should_allow :director do
      response.should be_success
      response.should render_template('facilities/manage')
    end

  end

  context "show" do
    before(:each) do
      @method = :get
      @action = :show
      @params = { id: facility.url_name }
    end

    it_should_allow_all ([ :guest ] + facility_operators) do
      expect(@controller.current_facility).to eq(facility)
      expect(response).to be_success
      expect(response).to render_template("facilities/show")
    end

    describe "daily view link" do
      let!(:instrument) { create(:instrument, facility: facility, facility_account: facility_account) }

      it "includes link to daily view", feature_setting: { daily_view: true } do
        do_request
        expect(response.body).to include("daily view")
      end

      it "does not include a link to the daily view when disabled", feature_setting: { daily_view: false } do
        do_request
        expect(response.body).not_to include("daily view")
      end
    end

    it "should 404 for invalid facility" do
      @params.merge!(id: 'randomstringofcharacters')
      do_request
      expect(response.code).to eq("404")
    end
  end

  context "list" do

    before(:each) do
      @method=:get
      @action=:list
    end

    it_should_require_login

    it_should_deny :guest

    context "as facility operators with two facilities" do

      before(:each) do
        @facility2 = FactoryGirl.create(:facility)
        @controller.stub(:current_facility).and_return(@authable)
        @controller.stub(:operable_facilities).and_return([@authable, @facility2])
        @controller.should_receive(:init_current_facility).never
      end

      it_should_allow_all facility_operators do
        assigns(:facilities).should == [@authable, @facility2]
        response.should be_success
        response.should render_template('facilities/list')
      end
    end

    context "as facility operators with one facility" do
      before(:each) do
        @controller.stub(:current_facility).and_return(@authable)
        @controller.should_receive(:init_current_facility).never
      end
      context 'has instruments' do
        before :each do
          FactoryGirl.create(:instrument, :facility => @authable, :facility_account => facility_account)
        end
        it_should_allow_all (facility_operators - [:admin]) do
          assigns(:facilities).should == [@authable]
          assigns(:operable_facilities).should == [@authable]
          response.should redirect_to(timeline_facility_reservations_path(@authable))
        end
      end
      context 'has no instruments' do
        # admin won't be redirected since their operable facilities is something more
        it_should_allow_all (facility_operators - [:admin]) do
          assigns(:facilities).should == [@authable]
          assigns(:operable_facilities).should == [@authable]
          response.should redirect_to(facility_orders_path(@authable))
        end
      end
    end

    context "as administrator" do

      before(:each) do
        @facility2 = FactoryGirl.create(:facility)
        @controller.stub(:current_facility).and_return(@authable)
      end

      it_should_allow :admin do
        assigns[:facilities].should == [@authable, @facility2]
        response.should be_success
        response.should render_template('facilities/list')
      end
    end

  end

  shared_context "transactions" do |action|
    before :each do
      @action = action
      @method = :get
      @params = { facility_id: @authable.url_name }
      @user = @admin
    end

    it_should_support_searching(:fulfilled_at)

    it "should use two column head" do
      sign_in @admin
      do_request
      expect(assigns[:layout]).to eq "two_column_head"
    end

    it "should query against the facility" do
      sign_in @admin
      do_request
      expect(assigns(:order_details)).to contain_string_in_sql "`orders`.`facility_id` = "
    end

    it_should_allow_managers_only
  end

  context "transactions" do
    it_behaves_like "transactions", :transactions
  end

  context "movable_transactions" do
    it_behaves_like "transactions", :movable_transactions
  end

end
