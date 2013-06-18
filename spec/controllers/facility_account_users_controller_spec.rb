require 'spec_helper'; require 'controller_spec_helper'

describe FacilityAccountUsersController, :if => SettingsHelper.feature_on?(:edit_accounts) do
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
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

    context 'changing roles' do
      before :each do
        maybe_grant_always_sign_in :director
      end

      context 'with an existing owner' do

        before :each do
          @params[:account_user][:user_role]=AccountUser::ACCOUNT_OWNER
          @account.account_users.owners.should be_one
          @account.owner_user.should == @owner
          do_request
        end

        it 'changes the owner of an account' do
          assigns(:account).should == @account
          assigns(:user).should == @purchaser
          assigns(:account_user).user_role.should == AccountUser::ACCOUNT_OWNER
          assigns(:account_user).user.should == @purchaser
          assigns(:account_user).created_by.should == @director.id
          # there will be two because the old owner record will have been expired
          @account.reload.account_users.owners.count.should == 2
          @account.account_users.owners.active.should be_one
          assigns(:account).reload.owner_user.should == @purchaser
          should set_the_flash
          assert_redirected_to facility_account_members_path(@authable, @account)
        end
      end


      context 'with a missing owner' do

        before :each do
          @acount_user = @account.owner
          AccountUser.delete(@acount_user.id)

          @params[:account_user][:user_role]=AccountUser::ACCOUNT_OWNER
          @account.account_users.owners.should_not be_any
          do_request
        end

        it 'adds the owner' do
          assigns(:account).should == @account
          @account.account_users.owners.count.should == 1
          should set_the_flash
          assert_redirected_to facility_account_members_path(@authable, @account)
        end
      end

      context "changing a user's role" do
        context 'from business admin to purchaser' do
          before :each do
            @business_admin = FactoryGirl.create(:user)
            FactoryGirl.create(:account_user, :account => @account, :user => @business_admin, :user_role => AccountUser::ACCOUNT_ADMINISTRATOR)
            @params.merge!(
              :account_id   => @account.id,
              :user_id      => @business_admin.id,
              :account_user => { :user_role => AccountUser::ACCOUNT_PURCHASER }
            )
            @account.account_users.purchasers.should_not be_any
            @account.account_users.business_administrators.should be_one
            do_request
          end

          it 'should change the role' do
            assigns(:account).should == @account
            @account.account_users.purchasers.map(&:user).should == [@business_admin]
            @account.account_users.business_administrators.should_not be_any

            should set_the_flash
            assert_redirected_to facility_account_members_path(@authable, @account)
          end
        end

        context 'from owner to purchaser' do
          before :each do
            @params[:user_id]                  = @owner.id
            @params[:account_user][:user_role] = AccountUser::ACCOUNT_PURCHASER
            @account.account_users.owners.map(&:user).should == [@owner]
            @account.account_users.purchasers.should_not be_any
          end

          it 'should be prevented' do
            do_request
            assigns(:account).should == @account
            assigns(:account).owner_user.should == @owner
            @account.account_users.owners.map(&:user).should == [@owner]
            @account.account_users.purchasers.should_not be_any

            flash[:error].should be_present
            response.should render_template :new
          end

          it 'should not send an email' do
            Notifier.should_not_receive(:user_update)
            do_request
          end
        end
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
