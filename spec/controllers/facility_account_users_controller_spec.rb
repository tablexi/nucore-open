require 'spec_helper'; require 'controller_spec_helper'

describe FacilityAccountUsersController do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @account=create_nufs_account_with_owner
  end


  context 'user_search' do

    before(:each) do
      @method=:get
      @action=:user_search
      @params={ :facility_id => @authable.url_name, :account_id => @account.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      should render_template('user_search')
    end

  end


  context 'new' do

    before(:each) do
      @method=:get
      @action=:new
      @params={ :facility_id => @authable.url_name, :account_id => @account.id, :user_id => @guest.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do
      assigns(:account).should == @account
      assigns(:user).should == @guest
      should assign_to(:account_user).with_kind_of(AccountUser)
      assigns(:account_user).should be_new_record
      should render_template('new')
    end

  end


  context 'create' do

    before(:each) do
      @method=:post
      @action=:create
      @params={
        :facility_id => @authable.url_name,
        :account_id => @account.id,
        :user_id => @purchaser.id,
        :account_user => { :user_role => AccountUser::ACCOUNT_PURCHASER }
      }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do |user|
      assigns(:account).should == @account
      assigns(:user).should == @purchaser
      assigns(:account_user).user_role.should == AccountUser::ACCOUNT_PURCHASER
      assigns(:account_user).user.should == @purchaser
      assigns(:account_user).created_by.should == user.id
      should set_the_flash
      assert_redirected_to facility_account_members_path(@authable, @account)
    end

  end


  context 'destroy' do

    before(:each) do
      @method=:delete
      @action=:destroy
      @account_user=Factory.create(:account_user, {
        :user => @purchaser,
        :account => @account,
        :user_role => AccountUser::ACCOUNT_PURCHASER,
        :created_by => @admin.id
      })
      @params={ :facility_id => @authable.url_name, :account_id => @account.id, :id => @account_user.id }
    end

    it_should_require_login

    it_should_deny :staff

    it_should_allow_all facility_managers do |user|
      assigns(:account).should == @account
      assigns(:account_user).should == @account_user
      assigns(:account_user).deleted_at.should_not be_nil
      assigns(:account_user).deleted_by.should == user.id
      should set_the_flash
      assert_redirected_to facility_account_members_path(@authable, @account)
    end

  end


end