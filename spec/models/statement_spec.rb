require 'spec_helper'

describe Statement do
  it "can be created with valid attributes" do
    @facility  = Factory.create(:facility)
    @statement = Statement.create({:facility => @facility, :created_by => 1, :invoice_date => Time.zone.now + 7.days})
    @statement.should be_valid
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
