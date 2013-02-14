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

  before(:each) do
    @authable = FactoryGirl.create(:facility)
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
      @method=:get
      @action=:show
      @params={ :id => @authable.url_name }
    end

    it_should_allow_all ([ :guest ] + facility_operators) do
      @controller.current_facility.should == @authable
      response.should be_success
      response.should render_template('facilities/show')
    end

    it 'should 404 for invalid facility' do
      @params.merge!({:id => 'randomstringofcharacters'})
      do_request
      response.code.should == "404"
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
          @facility_account = FactoryGirl.create(:facility_account, :facility => @authable)
          FactoryGirl.create(:instrument, :facility => @authable, :facility_account => @facility_account)
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

  context "transactions" do
    before(:each) do
      @action = :transactions
      @method = :get
      @params = { :facility_id => @authable.url_name }
      @user = @admin
    end

    it_should_support_searching(:fulfilled_at)

    it "should use two column head" do
      sign_in @admin
      do_request
      assigns[:layout].should == 'two_column_head'
    end

    it "should query against the facility" do
      sign_in @admin
      do_request
      assigns(:order_details).should contain_string_in_sql("`orders`.`facility_id` = ")
    end

    it_should_deny_all [:senior_staff, :staff]

  end

end
