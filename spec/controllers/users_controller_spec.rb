require 'spec_helper'; require 'controller_spec_helper'

describe UsersController do
  render_views

  it "should route" do
    { :get => "/facilities/url_name/users/new_search" }.should route_to(:controller => 'users', :action => 'new_search', :facility_id => 'url_name')
    { :post => "/facilities/url_name/users" }.should route_to(:controller => 'users', :action => 'create', :facility_id => 'url_name')
  end

  before(:all) { create_users }

  before(:each) do
    @authable = Factory.create(:facility)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_operators_only

  end


  context 'new' do

    before :each do
      @method=:get
      @action=:new
    end

    it_should_allow_operators_only do
      should assign_to(:user).with_kind_of User
      assigns(:user).should be_new_record
    end

  end


  context "create" do

    before :each do
      @method=:post
      @action=:create
      @params.merge!(:group_name => UserRole::FACILITY_DIRECTOR, :user => Factory.attributes_for(:user))
    end

    it_should_allow_operators_only :redirect do
      should assign_to(:user).with_kind_of User
      should set_the_flash
      assigns[:current_facility].should == @authable
      assert_redirected_to facility_users_url
    end

  end


  context 'new_search' do

    before :each do
      @method=:get
      @action=:new_search
      @params.merge!(:username => 'guest')
    end

    it_should_allow_operators_only :redirect do
      assigns(:user).should == @guest
      should set_the_flash
      assert_redirected_to facility_users_url(@authable)
    end

  end


  context 'username_search' do

    before :each do
      @method=:get
      @action=:username_search
      @params.merge!(:username_lookup => 'guest')
    end

    it_should_allow_operators_only do
      assigns(:user).username.should == @guest.username
    end

  end


  context 'switch_to' do

    before :each do
      @method=:get
      @action=:switch_to
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only :redirect do
      assigns(:user).should == @guest
      session[:acting_user_id].should == @guest.id
      session[:acting_ref_url].should == facility_users_url
      assert_redirected_to facilities_path
    end

  end

  context "orders" do
    before :each do
      @method=:get
      @action=:orders
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only do
      should assign_to(:current_facility).with(@authable)
      should assign_to(:user).with(@guest)
      should assign_to(:order_details).with_kind_of Array
    end
  end

  context "reservations" do
    before :each do
      @method=:get
      @action=:reservations
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only do
      should assign_to(:current_facility).with(@authable)
      should assign_to(:user).with(@guest)
      should assign_to(:order_details).with_kind_of Array
    end
  end

end
