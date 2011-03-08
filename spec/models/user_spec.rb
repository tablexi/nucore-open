require 'spec_helper'

describe User do

  it "should validate uniquess of username" do
    # we need at least 1 user to test validations
    user = Factory.create(:user)
    should validate_uniqueness_of(:username)
  end

  it "should use factory" do
    user = Factory.create(:user)
    user.should be_valid
  end

  it "should belong to NU price group if the username does not have an \"@\" symbol" do
    user = Factory.create(:user) # factory username = "username#{n}"
    user.price_groups.include?(@nupg).should == true
  end

  it "should belong to External price group if the username has an \"@\" symbol" do
    user = User.new(Factory.attributes_for(:user))
    user.username = user.email
    user.save
    user.price_groups.include?(@epg).should == true
  end

  it "should be a member of any explicitly mapped price groups" do
    user     = Factory.create(:user)
    facility = Factory.create(:facility)
    pg       = facility.price_groups.create(Factory.attributes_for(:price_group))
    UserPriceGroupMember.create(:user => user, :price_group => pg)
    user.price_groups.include?(pg).should == true
  end

  it "should belong to price groups of accounts" do
    user     = Factory.create(:user)
    cc       = Factory.create(:credit_card_account, :account_users_attributes => [{:user => user, :created_by => user, :user_role => 'Owner'}])
    facility = Factory.create(:facility)
    pg       = facility.price_groups.create(Factory.attributes_for(:price_group))
    AccountPriceGroupMember.create(:account => cc, :price_group => pg)
    user.account_price_groups.include?(pg).should == true
  end

  it "should belong to price groups of account owner" do
    owner    = Factory.create(:user)
    cc       = Factory.create(:credit_card_account, :account_users_attributes => [{:user => owner, :created_by => owner, :user_role => 'Owner'}])
    facility = Factory.create(:facility)
    pg       = facility.price_groups.create(Factory.attributes_for(:price_group))
    UserPriceGroupMember.create(:user => owner, :price_group => pg)

    user     = Factory.create(:user)
    cc.account_users.create(:user => user, :created_by => owner, :user_role => 'Purchaser')

    user.account_price_groups.include?(pg).should == true
  end

  it "should belong to Cancer Center price group if the user is in the Cancer Center view"

  it "cart should always return an order object with nil ordered_at"

end
