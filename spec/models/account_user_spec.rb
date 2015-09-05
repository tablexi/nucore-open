require "rails_helper"

RSpec.describe AccountUser do
  it "should create through account" do
    @user    = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @user))
    expect(@account).to be_valid
  end

  it "should allow only predefined roles" do
    AccountUser.user_roles.each do |role|
      @au = AccountUser.new({:user_role => role})
      @au.valid?
      expect(@au.errors[:user_id]).to be_empty
    end

    @au = AccountUser.create({:user_role => nil})
    expect(@au.errors[:user_id]).not_to be_nil

    @au = AccountUser.create({:user_role => 'NotAValidRole'})
    expect(@au.errors[:user_id]).not_to be_nil
  end

  it "should allow only one active role per user per account" do
    @user    = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @user))

    @au      = @account.account_users.create({:user => @user, :user_role => 'Purchaser', :created_by => @user.id})
    expect(@au.errors[:user_id]).not_to be_nil
  end

  it "should allow multiple inactive entries for the same user / role" do
    @user    = FactoryGirl.create(:user)
    @user2   = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @user))

    @au_deleted = @account.account_users.create(:user => @user2, :user_role => 'Purchaser', :created_by => @user.id, :deleted_at => Time.zone.now, :deleted_by => @user.id)
    @au         = @account.account_users.create(:user => @user2, :user_role => 'Purchaser', :created_by => @user.id)

    expect(@au.errors[:user_id]).to be_empty
  end

  it "should not allow multiple active account owners" do
    @user1   = FactoryGirl.create(:user)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @user1))

    @user2   = FactoryGirl.create(:user)
    @au = @account.account_users.create({:user => @user2, :user_role => 'Owner', :created_by => @user1.id})
    expect(@au.errors[:user_role]).not_to be_nil
  end


  context 'selectable_user_roles' do

    it 'should not include account owner role by default' do
      roles=AccountUser.selectable_user_roles
      expect(roles).not_to be_include AccountUser::ACCOUNT_OWNER
    end


    context 'with manager' do

      before :each do
        @user=FactoryGirl.create(:user)
        @facility=FactoryGirl.create(:facility)
        UserRole.grant(@user, UserRole::FACILITY_DIRECTOR, @facility)
        expect(@user).to be_manager_of @facility
      end

      it 'should not include account owner role without facility' do
        roles=AccountUser.selectable_user_roles(@user)
        expect(roles).not_to be_include AccountUser::ACCOUNT_OWNER
      end

      it 'should not include account owner role without user' do
        roles=AccountUser.selectable_user_roles(nil, @facility)
        expect(roles).not_to be_include AccountUser::ACCOUNT_OWNER
      end

      it 'should include account owner role if called by manager' do
        roles=AccountUser.selectable_user_roles(@user, @facility)
        expect(roles).to be_include AccountUser::ACCOUNT_OWNER
      end

    end
  end
end
