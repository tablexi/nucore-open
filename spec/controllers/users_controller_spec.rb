require 'spec_helper'; require 'controller_spec_helper'

describe UsersController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryGirl.create(:facility)
    @params={ :facility_id => @authable.url_name }
  end


  context 'index' do

    before :each do
      @method=:get
      @action=:index
      @inactive_user = FactoryGirl.create(:user, :first_name => 'Inactive')

      @active_user = FactoryGirl.create(:user, :first_name => 'Active')
      place_and_complete_item_order(@active_user, @authable)
      # place two orders to make sure it only and_return the user once
      place_and_complete_item_order(@active_user, @authable)
      
      @lapsed_user = FactoryGirl.create(:user, :first_name => 'Lapsed')
      @old_order_detail = place_and_complete_item_order(@lapsed_user, @authable)
      @old_order_detail.order.update_attributes(:ordered_at => 400.days.ago)
    end

    it_should_allow_operators_only :success, 'include the right users' do
      assigns[:users].size.should == 1
      assigns[:users].should include @active_user
    end

    context 'with newly created user' do
      before :each do
        @user = FactoryGirl.create(:user)
        @params.merge!({ :user => @user.id })
      end
      it_should_allow_operators_only :success, 'set the user' do
        assigns[:new_user].should == @user
      end
    end

  end


  context 'create user', :if => SettingsHelper.feature_on?(:create_users) do
    it "should route" do
      { :get => "/facilities/url_name/users/new_search" }.should route_to(:controller => 'users', :action => 'new_search', :facility_id => 'url_name')
      { :post => "/facilities/url_name/users" }.should route_to(:controller => 'users', :action => 'create', :facility_id => 'url_name')
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
        @params.merge!(:group_name => UserRole::FACILITY_DIRECTOR, :user => FactoryGirl.attributes_for(:user))
      end

      it_should_allow_operators_only :redirect do
        should assign_to(:user).with_kind_of User
        assert_redirected_to facility_users_url(:user => assigns[:user].id)
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
      session[:acting_ref_url].should == facility_users_path
      assert_redirected_to facility_path(@authable)
    end

  end

  context "orders" do
    before :each do
      @method=:get
      @action=:orders
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only do
      should assign_to(:user).with(@guest)
      should assign_to(:order_details).with_kind_of ActiveRecord::Relation
    end
  end

  context "reservations" do
    before :each do
      @method=:get
      @action=:reservations
      @params.merge!(:user_id => @guest.id)
    end

    it_should_allow_operators_only do
      should assign_to(:user).with(@guest)
      should assign_to(:order_details).with_kind_of ActiveRecord::Relation
    end
  end

end
