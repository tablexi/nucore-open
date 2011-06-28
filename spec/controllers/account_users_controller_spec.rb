require 'spec_helper'; require 'controller_spec_helper'

describe AccountUsersController do
  render_views

  before(:all) { create_users }

  before :each do
    @authable=create_nufs_account_with_owner
  end


  context 'user_search' do

    before :each do
      @method=:get
      @action=:user_search
      @params={ :account_id => @authable.id }
    end
    
    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      should render_template('user_search')
    end

  end


  context 'new' do

    before :each do
      @method=:get
      @action=:new
      @params={ :account_id => @authable.id, :user_id => @purchaser }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      assigns(:user).should == @purchaser
      should assign_to(:account_user).with_kind_of(AccountUser)
      assigns(:account_user).should be_new_record
      should render_template('new')
    end

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @params={
        :account_id => @authable.id,
        :user_id => @purchaser.id,
        :account_user => { :user_role => AccountUser::ACCOUNT_PURCHASER }
      }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      assigns(:user).should == @purchaser
      should assign_to(:account_user).with_kind_of(AccountUser)
      assigns(:account_user).user.should == @purchaser
      assigns(:account_user).created_by.should == @owner.id
      @purchaser.reload.should be_purchaser_of(@authable)
      should set_the_flash
      assert_redirected_to(account_account_users_path(@authable))
    end

  end


  context 'destroy' do

    before :each do
      @method=:delete
      @action=:destroy
      @account_user=Factory.create(:account_user, {
        :user_role => AccountUser::ACCOUNT_ADMINISTRATOR,
        :account_id => @authable.id,
        :user_id => @staff.id,
        :created_by => @admin.id
      })
      @params={ :account_id => @authable.id, :id => @account_user.id }
    end

    it_should_require_login

    it_should_deny :purchaser

    it_should_allow :owner do
      should assign_to(:account_user).with_kind_of(AccountUser)
      @account_user.reload
      @account_user.deleted_at.should_not be_nil
      @account_user.deleted_by.should == @owner.id
      should set_the_flash
      assert_redirected_to(account_account_users_path(@authable))
    end

  end

end