require 'spec_helper'

describe ProductUser do
  it "can be created with valid attributes" do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id, :requires_approval => true))
    @user             = Factory.create(:user)

    @product_user     = ProductUser.create({:product => @item, :user => @user, :approved_by => @user.id})
    @product_user.should be_valid
  end
  
  it "should assign approved_at on creation" do
    @facility         = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @item             = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id, :requires_approval => true))
    @user             = Factory.create(:user)

    @product_user     = ProductUser.create({:product => @item, :user => @user, :approved_by => @user.id})
    @product_user.approved_at.should_not be_nil
  end
  
  it "requires approved_by" do
    @product_user = ProductUser.new({:approved_by => nil})
    @product_user.should_not be_valid
    @product_user.errors.on(:approved_by).should_not be_nil
    
    @product_user = ProductUser.new({:approved_by => 1})
    @product_user.valid?
    @product_user.errors.on(:approved_by).should be_nil
  end
  
  it "requires product_id" do
    @product_user = ProductUser.new({:product_id => nil})
    @product_user.should_not be_valid
    @product_user.errors.on(:product_id).should_not be_nil
    
    @product_user = ProductUser.new({:product_id => 1})
    @product_user.valid?
    @product_user.errors.on(:product_id).should be_nil
  end
  
  it "requires user_id" do
    @product_user = ProductUser.new({:user_id => nil})
    @product_user.should_not be_valid
    @product_user.errors.on(:user_id).should_not be_nil
    
    @product_user = ProductUser.new({:user_id => 1})
    @product_user.valid?
    @product_user.errors.on(:user_id).should be_nil
  end
end
