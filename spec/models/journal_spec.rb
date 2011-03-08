require 'spec_helper'

describe Journal do
  it "can be created with valid attributes" do
    @facility = Factory.create(:facility)
    @journal  = Journal.new(:facility => @facility, :created_by => 1)
    @journal.should be_valid
    @journal.save
    @journal.id.should_not be_nil
  end
  
  it "allows only one active journal per facility" do
    @facility = Factory.create(:facility)
    @journal1 = Journal.create(:facility => @facility, :created_by => 1)
    @journal1.id.should_not be_nil
    
    @journal2 = Journal.create(:facility => @facility, :created_by => 1)
    @journal2.should_not be_valid
    
    @journal1.update_attributes({:is_successful => false, :reference => '12345', :updated_by => 1})
    @journal1.should be_valid
    @journal2.should be_valid
  end
  
  it "requires reference on update" do
    @facility = Factory.create(:facility)
    @journal  = Journal.create(:facility => @facility, :created_by => 1)
    @journal.valid?
    @journal.errors.on(:reference).should_not be_nil
    
    @journal.reference = '12345'
    @journal.valid?
    @journal.errors.on(:reference).should be_nil
  end
  
  it "requires updated_by on update" do
    @facility = Factory.create(:facility)
    @journal  = Journal.create(:facility => @facility, :created_by => 1)
    @journal.valid?
    @journal.errors.on(:updated_by).should_not be_nil
    
    @journal.updated_by = '1'
    @journal.valid?
    @journal.errors.on(:updated_by).should be_nil
  end
  
  it "requires a boolean value for is_successful on update" do
    @facility = Factory.create(:facility)
    @journal  = Journal.create(:facility => @facility, :created_by => 1)
    @journal.valid?
    @journal.errors.on(:is_successful).should_not be_nil
    
    @journal.is_successful = true
    @journal.valid?
    @journal.errors.on(:is_successful).should be_nil
    
    @journal.is_successful = false
    @journal.valid?
    @journal.errors.on(:is_successful).should be_nil
  end
  
  it "should create and attach journal spreadsheet" do
    @facility = Factory.create(:facility)
    @journal  = Journal.create(:facility => @facility, :created_by => 1)
    @journal.valid?
    # create nufs account
    @owner    = Factory.create(:user)
    hash      = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
    @account  = Factory.create(:nufs_account, :account_users_attributes => [hash])
    @journal.create_spreadsheet
    # @journal.add_spreadsheet("#{Rails.root}/spec/files/nucore.journal.template.xls")
    @journal.file.url.should =~ /^\/files/
  end
end