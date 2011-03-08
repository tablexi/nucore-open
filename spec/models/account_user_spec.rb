require 'spec_helper'

describe AccountUser do
  it "should create through account" do
    @user    = Factory.create(:user)
    @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user.id, :user_role => 'Owner']])
    @account.should be_valid
  end
  
  it "should allow only predefined roles" do
    AccountUser.user_roles.each do |role|
      @au = AccountUser.new({:user_role => role})
      @au.valid?
      @au.errors.on(:user_role).should be_nil
    end

    @au = AccountUser.create({:user_role => nil})
    @au.errors.on(:user_role).should_not be_nil

    @au = AccountUser.create({:user_role => 'NotAValidRole'})
    @au.errors.on(:user_role).should_not be_nil
  end
  
  it "should allow only one active role per user per account" do
    @user    = Factory.create(:user)
    @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user.id, :user_role => 'Owner']])
    
    @au      = @account.account_users.create({:user => @user, :user_role => 'Purchaser', :created_by => @user.id})
    @au.errors.on(:user_id).should_not be_nil
  end

  it "should allow multiple inactive entries for the same user / role" do
    @user    = Factory.create(:user)
    @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user.id, :user_role => 'Owner', :deleted_at => Time.zone.now, :deleted_by => @user.id]])
    
    @au      = @account.account_users.create({:user => @user, :user_role => 'Purchaser', :created_by => @user.id})
    @au.errors.on(:user_id).should be_nil
  end
  
  it "should not allow multiple active account owners" do
    @user1   = Factory.create(:user)
    @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user1, :created_by => @user1.id, :user_role => 'Owner']])
    
    @user2   = Factory.create(:user)
    @au = @account.account_users.create({:user => @user2, :user_role => 'Owner', :created_by => @user1.id})
    @au.errors.on(:user_role).should_not be_nil
  end
end
