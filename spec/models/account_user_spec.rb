require 'spec_helper'

describe AccountUser do
  it "should create through account" do
    @user    = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user.id, :user_role => 'Owner']])
    @account.should be_valid
  end

  it "should allow only predefined roles" do
    AccountUser.user_roles.each do |role|
      @au = AccountUser.new({:user_role => role})
      @au.valid?
      @au.errors[:user_id].should be_empty
    end

    @au = AccountUser.create({:user_role => nil})
    @au.errors[:user_id].should_not be_nil

    @au = AccountUser.create({:user_role => 'NotAValidRole'})
    @au.errors[:user_id].should_not be_nil
  end

  it "should allow only one active role per user per account" do
    @user    = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user.id, :user_role => 'Owner']])

    @au      = @account.account_users.create({:user => @user, :user_role => 'Purchaser', :created_by => @user.id})
    @au.errors[:user_id].should_not be_nil
  end

  it "should allow multiple inactive entries for the same user / role" do
    @user    = FactoryGirl.create(:user)
    @user2   = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user.id, :user_role => 'Owner']])


    @au_deleted = @account.account_users.create({:user => @user2, :user_role => 'Purchaser', :created_by => @user.id, :deleted_at => Time.zone.now, :deleted_by => @user.id})
    @au         = @account.account_users.create({:user => @user2, :user_role => 'Purchaser', :created_by => @user.id})

    @au.errors[:user_id].should be_empty
  end

  it "should not allow multiple active account owners" do
    @user1   = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user1, :created_by => @user1.id, :user_role => 'Owner']])

    @user2   = FactoryGirl.create(:user)
    @au = @account.account_users.create({:user => @user2, :user_role => 'Owner', :created_by => @user1.id})
    @au.errors[:user_role].should_not be_nil
  end


  context 'selectable_user_roles' do

    it 'should not include account owner role by default' do
      roles=AccountUser.selectable_user_roles
      roles.should_not be_include AccountUser::ACCOUNT_OWNER
    end


    context 'with manager' do

      before :each do
        @user=FactoryGirl.create(:user)
        @facility=FactoryGirl.create(:facility)
        UserRole.grant(@user, UserRole::FACILITY_DIRECTOR, @facility)
        @user.should be_manager_of @facility
      end

      it 'should not include account owner role without facility' do
        roles=AccountUser.selectable_user_roles(@user)
        roles.should_not be_include AccountUser::ACCOUNT_OWNER
      end

      it 'should not include account owner role without user' do
        roles=AccountUser.selectable_user_roles(nil, @facility)
        roles.should_not be_include AccountUser::ACCOUNT_OWNER
      end

      it 'should include account owner role if called by manager' do
        roles=AccountUser.selectable_user_roles(@user, @facility)
        roles.should be_include AccountUser::ACCOUNT_OWNER
      end

    end
  end
end
