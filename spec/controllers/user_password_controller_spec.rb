require "rails_helper"
require 'controller_spec_helper'

  def it_should_deny_if_signed_in
    it "should not allow if you're signed in" do
      sign_in(@user)
      do_request
      expect(response).to redirect_to(edit_current_password_path)
    end
  end

RSpec.describe UserPasswordController, :if => SettingsHelper.feature_on?(:password_update) do
  render_views


  context "password change" do
    before :each do
      @method = :get
      @action = :edit_current
      @user = FactoryGirl.create(:user, :username => 'email@example.org', :email => 'email@example.org')
    end
    it_should_require_login

    it "should not allow someone who is authenticated elsewhere" do
      @user = FactoryGirl.create(:user)
      sign_in(@user)
      do_request
      expect(response).to render_template("user_password/no_password")
    end

    it "should throw errors if blank" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => "", :password_confirmation => "", :current_password => 'password'}}
      do_request
      expect(response).to render_template("user_password/edit_current")
      expect(assigns[:user].errors).not_to be_empty
      expect(@user.reload).to be_valid_password('password')
    end

    it "should throw errors if passwords don't match" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'password1', :password_confirmation => 'password2', :current_password => 'password'}}
      do_request
      expect(response).to render_template("user_password/edit_current")
      expect(assigns[:user].errors).not_to be_empty
      expect(@user.reload).to be_valid_password('password')
    end

    it "should display errors if the current password is incorrect" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'password1', :password_confirmation => 'password1', :current_password => 'incorrectpassword'}}
      do_request
      expect(response).to render_template("user_password/edit_current")
      expect(assigns[:user].errors).not_to be_empty
      expect(@user.reload).to be_valid_password('password')
    end

    it "should update password" do
      sign_in(@user)
      @method = :post
      @params = {:user => {:password => 'newpassword', :password_confirmation => 'newpassword', :current_password => 'password'}}
      do_request
      expect(response).to render_template("user_password/edit_current")
      expect(assigns[:user].errors).to be_empty
      expect(flash[:notice]).not_to be_nil
      expect(@user.reload).to be_valid_password('newpassword')
    end

  end

  context "change password link" do
    before :each do
      @method = :get
      @action = :edit_current
    end

    it "should show for 'external' users" do
      @user = FactoryGirl.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      expect(@user).to be_external
      sign_in @user
      do_request
      expect(response).to be_success
      expect(response.body).to include("Change Password</a>")
    end

    it "should not show for netid or ldap people" do
      @user = FactoryGirl.create(:user)
      expect(@user).not_to be_external
      sign_in @user
      do_request
      expect(response.body).not_to include("Change Password</a>")
    end
  end


  context "reset password" do
    before :each do
      @method = :post
      @action = :reset
      @user = @db_user = FactoryGirl.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @remote_authenticated_user = FactoryGirl.create(:user)
    end
    it "should display the page on get" do
      @method = :get
      do_request
      expect(response).to be_success
      expect(response).to render_template "user_password/reset"
      expect(response).to render_template "layouts/application"
      expect(assigns[:user]).to be_nil
    end

    it_should_deny_if_signed_in

    it "should not find someone" do
      @params = {:user => {:email => 'xxxxx'}}
      do_request
      expect(response).to render_template "user_password/reset"
      expect(response).to render_template "layouts/application"
      expect(assigns[:user]).to be_nil
      expect(flash[:error]).not_to be_nil
      expect(flash[:error]).to include "xxxxx"
    end

    it "should not be able to do anything for non-local users" do
      @params = {:user => {:email => @remote_authenticated_user.email}}
      do_request
      expect(response).to render_template "user_password/reset"
      expect(response).to render_template "layouts/application"
      expect(assigns[:user]).to eq(@remote_authenticated_user)
      expect(flash[:error]).not_to be_nil
    end

    it "should send a notification and set a new token" do
      @params = {:user => {:email => @db_user.email}}
      expect(@db_user.reset_password_token).to be_nil
      do_request
      assigns[:user] == @db_user
      expect(flash[:error]).to be_nil
      expect(flash[:notice]).not_to be_nil
      expect(assigns[:user].reset_password_token).not_to be_nil
      expect(response).to redirect_to(new_user_session_path)

    end
  end

  context "edit" do
    before :each do
      @method = :get
      @action = :edit
      @user = FactoryGirl.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @user.send(:generate_reset_password_token!)
      @params = {:reset_password_token => @user.reset_password_token}
    end
    it_should_deny_if_signed_in

    it "should redirect if there isn't a valid token" do
      @params = {:reset_password_token => "xxxxx"}
      do_request
      expect(response).to redirect_to(reset_password_path)
      expect(flash[:error]).not_to be_nil
    end

    it "should display if the token is valid" do
      do_request
      expect(response).to render_template "user_password/edit"
    end

    it "should show error if token expired" do
      @user.reset_password_sent_at = @user.reset_password_sent_at - 2.days
      @user.save!
      do_request
      expect(response).to redirect_to(reset_password_path)
      expect(flash[:error]).not_to be_nil
    end
  end

  context "update" do
    before :each do
      @method = :put
      @action = :update
      @user = FactoryGirl.create(:user, :username => 'email@example.org', :email => 'email@example.org')
      @user.send(:generate_reset_password_token!)
      @params = {:user => {:reset_password_token => @user.reset_password_token}}
    end
    it_should_deny_if_signed_in

    it "should redirect if there isn't a valid token" do
      @params = {:user => {:reset_password_token => "xxxxx"}}
      do_request
      expect(response).to redirect_to(reset_password_path)
      expect(flash[:error]).not_to be_nil
    end

    it "should fail if passwords don't match" do
      @params.deep_merge!({:user => {:password => "newpassword", :password_confirmation => "anotherpassword"}})
      do_request
      expect(response).to render_template("user_password/edit")
      expect(assigns[:user].errors).not_to be_empty
    end

    it "should succeed" do
      @params.deep_merge!({:user => {:password => "newpassword", :password_confirmation => "newpassword"}})
      do_request
      expect(response).to redirect_to(:root)
      expect(assigns[:user]).to eq(@user)
      expect(assigns[:user].errors).to be_empty
      expect(flash[:notice]).not_to be_nil
      expect(assigns[:user].reload.valid_password?("newpassword")).to be true
      expect(assigns[:user].reset_password_token).to be_nil
    end
  end

end
