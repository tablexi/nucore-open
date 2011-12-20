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
      should assign_to(:current_facility).with(@authable)
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
      should assign_to(:current_facility).with(@authable)
      should assign_to(:user).with(@guest)
      should assign_to(:order_details).with_kind_of ActiveRecord::Relation
    end
  end
  
  context "password change" do
    before :each do
      @method = :get
      @action = :password
      @user = Factory.create(:user, :username => 'email@example.org', :email => 'email@example.org')
    end
    it_should_require_login
    
    it "should not allow someone who is authenticated elsewhere" do
      @user = Factory.create(:user)
      sign_in(@user)
      do_request
      response.should render_template("users/no_password")
    end
    
    it "should throw errors if blank" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => "", :password_confirmation => "", :current_password => 'password'}}
      do_request
      response.should render_template("users/password")
      assigns[:user].errors.should_not be_empty
      @user.reload.should be_valid_password('password')
    end
    
    it "should throw errors if passwords don't match" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'password1', :password_confirmation => 'password2', :current_password => 'password'}}
      do_request
      response.should render_template("users/password")
      assigns[:user].errors.should_not be_empty
      @user.reload.should be_valid_password('password')
    end
    
    it "should display errors if the current password is incorrect" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'password1', :password_confirmation => 'password1', :current_password => 'incorrectpassword'}}
      do_request
      response.should render_template("users/password")
      assigns[:user].errors.should_not be_empty
      @user.reload.should be_valid_password('password')
    end
    
    it "should update password" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'newpassword', :password_confirmation => 'newpassword', :current_password => 'password'}}
      do_request
      response.should render_template("users/password")
      assigns[:user].errors.should be_empty
      flash[:notice].should_not be_nil
      @user.reload.should be_valid_password('newpassword')
    end
    
  end
  
  context "change password link" do
    before :each do
      @method = :get
      @action = :password
    end
    
    it "should show for 'external' users" do
      @user = Factory.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @user.should be_external
      sign_in @user
      do_request
      response.body.should include("Change Password</a>")
    end
    
    it "should not show for netid or ldap people" do
      @user = Factory.create(:user)
      @user.should_not be_external
      sign_in @user
      do_request
      response.body.should_not include("Change Password</a>")
    end
  end
  
  context "reset password" do
    before :each do
      @method = :post
      @action = :password_reset
      @db_user = Factory.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @remote_authenticated_user = Factory.create(:user)
    end
    it "should display the page on get" do
      @method = :get
      do_request
      response.should be_success
      response.should render_template "users/password_reset"
      response.should render_template "layouts/application"
      assigns[:user].should be_nil
    end
    
    it "should not find someone" do
      @params = {:user => {:email => 'xxxxx'}}
      do_request
      response.should render_template "users/password_reset"
      response.should render_template "layouts/application"
      assigns[:user].should be_nil
      flash[:error].should_not be_nil
      flash[:error].should include "xxxxx"
    end
    
    it "should not be able to do anything for non-local users" do
      @params = {:user => {:email => @remote_authenticated_user.email}}
      do_request
      response.should render_template "users/password_reset"
      response.should render_template "layouts/application"
      assigns[:user].should == @remote_authenticated_user
      flash[:error].should_not be_nil
    end
    
    it "should send a notification and set a new token" do
      @params = {:user => {:email => @db_user.email}}
      @db_user.reset_password_token.should be_nil
      do_request
      response.should render_template "users/password_reset"
      response.should render_template "layouts/application"
      assigns[:user] == @db_user
      flash[:error].should be_nil
      flash[:notice].should_not be_nil
      assigns[:user].reset_password_token.should_not be_nil

    end
  end


end
