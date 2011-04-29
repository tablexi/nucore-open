require 'spec_helper'

describe StatementRow do

  before :each do
    @user=Factory.create(:user)
    @facility=Factory.create(:facility)
    @statement=Factory.create(:statement, :facility => @facility, :created_by => @user.id, :invoice_date => Time.zone.now)
    @account=Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
  end


  it 'should create' do
    assert_nothing_raised do
      StatementRow.create!(:account => @account, :statement => @statement, :amount => 9.23)
    end
  end


  it { should validate_presence_of :account_id }
  it { should validate_presence_of :statement_id }
  it { should validate_numericality_of :amount }
  
end