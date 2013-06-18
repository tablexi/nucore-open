require 'spec_helper'; require 'controller_spec_helper'

describe FacilityAccountUsersController, :if => SettingsHelper.feature_on?(:edit_accounts) do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @account=create_nufs_account_with_owner
    @account_with_business_admin=create_nufs_account_with_owner_and_business_admin
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

    context 'change owner' do

      before :each do
        @params[:account_user][:user_role]=AccountUser::ACCOUNT_OWNER
        AccountUser.where(:account_id => @account.id, :user_role => AccountUser::ACCOUNT_OWNER).all.size.should == 1
        @account.owner_user.should == @owner
      end

      it_should_allow :director, 'to change the owner of an account' do
        assigns(:account).should == @account
        assigns(:user).should == @purchaser
        assigns(:account_user).user_role.should == AccountUser::ACCOUNT_OWNER
        assigns(:account_user).user.should == @purchaser
        assigns(:account_user).created_by.should == @director.id
        # there will be two because the old owner record will have been expired
        AccountUser.where(:account_id => @account.id, :user_role => AccountUser::ACCOUNT_OWNER).all.size.should == 2
        assigns(:account).reload.owner_user.should == @purchaser
        should set_the_flash
        assert_redirected_to facility_account_members_path(@authable, @account)
      end
    end

    context 'add owner' do

      before :each do
        @acount_user = @account.owner
        AccountUser.delete(@acount_user.id)

        @params[:account_user][:user_role]=AccountUser::ACCOUNT_OWNER
        AccountUser.where(:account_id => @account.id, :user_role => AccountUser::ACCOUNT_OWNER).all.size.should == 0
      end

      it_should_allow :director, 'to add owner to account without owner' do
        assigns(:account).should == @account
        AccountUser.where(:account_id => @account.id, :user_role => AccountUser::ACCOUNT_OWNER).all.size.should == 1
        should set_the_flash
        assert_redirected_to facility_account_members_path(@authable, @account)
      end
    end

    context 'change user user_role' do

      before :each do
        @business_admin = @account_with_business_admin.business_admins.first
        @params.merge!(
          :account_id   => @account_with_business_admin.id,
          :user_id      => @business_admin.user.id,
          :account_user => { :user_role => AccountUser::ACCOUNT_PURCHASER }
        )

        AccountUser.where(:account_id => @account_with_business_admin.id, :user_role => AccountUser::ACCOUNT_PURCHASER).all.size.should == 0
        AccountUser.where(:account_id => @account_with_business_admin.id, :user_role => AccountUser::ACCOUNT_ADMINISTRATOR).all.size.should == 1
      end

      it_should_allow :director, 'to change business admin to purchaser' do
        assigns(:account).should == @account_with_business_admin
        AccountUser.where(:account_id => @account_with_business_admin.id, :user_role => AccountUser::ACCOUNT_PURCHASER).all.size.should == 1
        AccountUser.where(:account_id => @account_with_business_admin.id, :user_role => AccountUser::ACCOUNT_ADMINISTRATOR).all.size.should == 0
        should set_the_flash
        assert_redirected_to facility_account_members_path(@authable, @account_with_business_admin)
      end
    end

    context 'change owner user_role' do

      before :each do
        @params[:user_id]                  = @owner.id
        @params[:account_user][:user_role] = AccountUser::ACCOUNT_PURCHASER

        @account.owner_user.should == @owner
        AccountUser.where(:account_id => @account.id, :user_role => AccountUser::ACCOUNT_OWNER).all.size.should == 1
        AccountUser.where(:account_id => @account.id, :user_role => AccountUser::ACCOUNT_PURCHASER).all.size.should == 0
      end

      it_should_not_allow :director, 'to change user role' do
        assigns(:account).should == @account
        assigns(:account).owner_user.should == @owner
        AccountUser.where(:account_id => @account.id, :user_role => AccountUser::ACCOUNT_OWNER).all.size.should == 1
        AccountUser.where(:account_id => @account.id, :user_role => AccountUser::ACCOUNT_PURCHASER).all.size.should == 0
        should set_the_flash
        assert_redirected_to facility_account_members_path(@authable, @account)
      end
    end

  end


  context 'destroy' do

    before(:each) do
      @method=:delete
      @action=:destroy
      @account_user=FactoryGirl.create(:account_user, {
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
