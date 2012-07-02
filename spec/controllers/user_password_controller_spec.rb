require 'spec_helper'
require 'controller_spec_helper'

  def it_should_deny_if_signed_in
    it "should not allow if you're signed in" do
      sign_in(@user)
      do_request
      response.should redirect_to(edit_current_password_path)
    end
  end

describe UserPasswordController, :if => SettingsHelper.feature_on?(:password_update) do
  render_views

    
  context "password change" do
    before :each do
      @method = :get
      @action = :edit_current
      @user = Factory.create(:user, :username => 'email@example.org', :email => 'email@example.org')
    end
    it_should_require_login
    
    it "should not allow someone who is authenticated elsewhere" do
      @user = Factory.create(:user)
      sign_in(@user)
      do_request
      response.should render_template("user_password/no_password")
    end
    
    it "should throw errors if blank" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => "", :password_confirmation => "", :current_password => 'password'}}
      do_request
      response.should render_template("user_password/edit_current")
      assigns[:user].errors.should_not be_empty
      @user.reload.should be_valid_password('password')
    end
    
    it "should throw errors if passwords don't match" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'password1', :password_confirmation => 'password2', :current_password => 'password'}}
      do_request
      response.should render_template("user_password/edit_current")
      assigns[:user].errors.should_not be_empty
      @user.reload.should be_valid_password('password')
    end
    
    it "should display errors if the current password is incorrect" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'password1', :password_confirmation => 'password1', :current_password => 'incorrectpassword'}}
      do_request
      response.should render_template("user_password/edit_current")
      assigns[:user].errors.should_not be_empty
      @user.reload.should be_valid_password('password')
    end
    
    it "should update password" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'newpassword', :password_confirmation => 'newpassword', :current_password => 'password'}}
      do_request
      response.should render_template("user_password/edit_current")
      assigns[:user].errors.should be_empty
      flash[:notice].should_not be_nil
      @user.reload.should be_valid_password('newpassword')
    end
    
  end
  
  context "change password link" do
    before :each do
      @method = :get
      @action = :edit_current
    end
    
    it "should show for 'external' users" do
      @user = Factory.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @user.should be_external
      sign_in @user
      do_request
      response.should be_success
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
      @action = :reset
      @user = @db_user = Factory.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @remote_authenticated_user = Factory.create(:user)
    end
    it "should display the page on get" do
      @method = :get
      do_request
      response.should be_success
      response.should render_template "user_password/reset"
      response.should render_template "layouts/application"
      assigns[:user].should be_nil
    end
    
    it_should_deny_if_signed_in
    
    it "should not find someone" do
      @params = {:user => {:email => 'xxxxx'}}
      do_request
      response.should render_template "user_password/reset"
      response.should render_template "layouts/application"
      assigns[:user].should be_nil
      flash[:error].should_not be_nil
      flash[:error].should include "xxxxx"
    end
    
    it "should not be able to do anything for non-local users" do
      @params = {:user => {:email => @remote_authenticated_user.email}}
      do_request
      response.should render_template "user_password/reset"
      response.should render_template "layouts/application"
      assigns[:user].should == @remote_authenticated_user
      flash[:error].should_not be_nil
    end
    
    it "should send a notification and set a new token" do
      @params = {:user => {:email => @db_user.email}}
      @db_user.reset_password_token.should be_nil
      do_request
      assigns[:user] == @db_user
      flash[:error].should be_nil
      flash[:notice].should_not be_nil
      assigns[:user].reset_password_token.should_not be_nil
      response.should redirect_to(new_user_session_path)

    end
  end
  
  context "edit" do
    before :each do
      @method = :get
      @action = :edit
      @user = Factory.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @user.send(:generate_reset_password_token!)
      @params = {:reset_password_token => @user.reset_password_token}
    end
    it_should_deny_if_signed_in
    
    it "should redirect if there isn't a valid token" do
      @params = {:reset_password_token => "xxxxx"}
      do_request
      response.should redirect_to(reset_password_path)
      flash[:error].should_not be_nil
    end
    
    it "should display if the token is valid" do
      do_request
      response.should render_template "user_password/edit"
    end
    
    it "should show error if token expired" do
      @user.reset_password_sent_at = @user.reset_password_sent_at - 2.days
      @user.save!
      do_request
      response.should redirect_to(reset_password_path)
      flash[:error].should_not be_nil
    end
  end
  
  context "update" do
    before :each do
      @method = :put
      @action = :update
      @user = Factory.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @user.send(:generate_reset_password_token!)
      @params = {:user => {:reset_password_token => @user.reset_password_token}}
    end
    it_should_deny_if_signed_in
    
    it "should redirect if there isn't a valid token" do
      @params = {:user => {:reset_password_token => "xxxxx"}}
      do_request
      response.should redirect_to(reset_password_path)
      flash[:error].should_not be_nil
    end
    
    it "should fail if passwords don't match" do
      @params.deep_merge!({:user => {:password => "newpassword", :password_confirmation => "anotherpassword"}})
      do_request
      response.should render_template("user_password/edit")
      assigns[:user].errors.should_not be_empty
    end
    
    it "should succeed" do
      @params.deep_merge!({:user => {:password => "newpassword", :password_confirmation => "newpassword"}})
      do_request
      response.should redirect_to(:root)
      assigns[:user].should == @user
      assigns[:user].errors.should be_empty
      flash[:notice].should_not be_nil
      assigns[:user].reload.valid_password?("newpassword").should be_true
      assigns[:user].reset_password_token.should be_nil
    end
  end

end
