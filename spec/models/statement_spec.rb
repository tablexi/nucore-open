require 'spec_helper'

describe Statement do
  it "can be created with valid attributes" do
    @facility=Factory.create(:facility)
    @user=Factory.create(:user)
    @account=Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @statement = Statement.create({:facility => @facility, :created_by => 1, :account => @account})
    @statement.should be_valid
  end

  context "finalized_at" do
    before :each do
      @facility  = Factory.create(:facility)
      @statement = Statement.create({:facility => @facility, :created_by => 1})
    end
  end

  it "requires created_by" do
    @statement = Statement.new({:created_by => nil})
    @statement.should_not be_valid
    @statement.errors.on(:created_by).should_not be_nil
    
    @statement = Statement.new({:created_by => 1})
    @statement.valid?
    @statement.errors.on(:created_by).should be_nil
  end
  
  it "requires a facility" do
    @statement = Statement.new({:facility_id => nil})
    @statement.should_not be_valid
    @statement.errors.on(:facility_id).should_not be_nil
    
    @statement = Statement.new({:facility_id => 1})
    @statement.valid?
    @statement.errors.on(:facility_id).should be_nil
  end
end
