require 'spec_helper'

describe Journal do

  before :each do
    @facility = Factory.create(:facility)
    @journal  = Journal.new(:facility => @facility, :created_by => 1, :journal_date => Time.zone.now)
  end

  it "can be created with valid attributes" do
    @journal.should be_valid
    @journal.save
    @journal.id.should_not be_nil
  end
  
  it "allows only one active journal per facility" do
    assert @journal.save
    @journal.id.should_not be_nil
    
    @journal2 = Journal.create(:facility => @facility, :created_by => 1, :journal_date => Time.zone.now)
    @journal2.should_not be_valid
    
    @journal.update_attributes({:is_successful => false, :reference => '12345', :updated_by => 1})
    @journal.should be_valid
    @journal2.should be_valid
  end
  
  it "requires reference on update" do
    assert @journal.save
    assert !@journal.save
    @journal.errors[:reference].should_not be_nil
    
    @journal.reference = '12345'
    @journal.valid?
    @journal.errors[:reference].should be_empty
  end
  
  it "requires updated_by on update" do
    assert @journal.save
    assert !@journal.save
    @journal.errors[:updated_by].should_not be_nil
    
    @journal.updated_by = '1'
    @journal.valid?
    @journal.errors[:updated_by].should be_empty
  end
  
  it "requires a boolean value for is_successful on update" do
    assert @journal.save
    assert !@journal.save
    @journal.errors[:is_successful].should_not be_nil
    
    @journal.is_successful = true
    @journal.valid?
    @journal.errors[:is_successful].should be_empty
    
    @journal.is_successful = false
    @journal.valid?
    @journal.errors[:is_successful].should be_empty
  end
  
  it "should create and attach journal spreadsheet" do
    @journal.valid?
    # create nufs account
    @owner    = Factory.create(:user)
    hash      = Hash[:user => @owner, :created_by => @owner, :user_role => 'Owner']
    @account  = Factory.create(:nufs_account, :account_users_attributes => [hash])
    @journal.create_spreadsheet
    # @journal.add_spreadsheet("#{Rails.root}/spec/files/nucore.journal.template.xls")
    @journal.file.url.should =~ /^\/files/
  end

  it 'should be open' do
    @journal.is_successful=nil
    @journal.should be_open
  end

  it 'should not be open' do
    @journal.is_successful=true
    @journal.should_not be_open
  end
end