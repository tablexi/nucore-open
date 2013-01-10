require 'spec_helper'

describe Facility do

  it "should require name" do
    should validate_presence_of(:name)
  end

  it "should require abbreviation" do
    should validate_presence_of(:abbreviation)
  end

  context "url_name" do
    it "is only valid with alphanumeric and -_ characters" do
      should_not allow_value('abc 123').for(:url_name)
      should allow_value('abc-123').for(:url_name)
      should allow_value('abc123').for(:url_name)
    end

    it "is not valid with less than 3 or longer than 50 characters" do
      should_not allow_value('123456789012345678901234567890123456789012345678901').for(:url_name) # 51 chars
      should_not allow_value('12').for(:url_name)
      should_not allow_value('').for(:url_name)
      should_not allow_value(nil).for(:url_name)
     end

    it "is valid between 3 and 50 characters" do
      should allow_value('123').for(:url_name)
      should allow_value('12345678901234567890123456789012345678901234567890').for(:url_name) # 50 chars
    end

    it "is unique" do
      @factory1 = FactoryGirl.create(:facility)
      @factory2 = FactoryGirl.build(:facility, :url_name => @factory1.url_name)
      @factory2.should_not be_valid
    end
  end
  
  context "lookup ids by urls" do
    before :each do
      @facility = FactoryGirl.create(:facility)
      @facility2 = FactoryGirl.create(:facility)
      @facility3 = FactoryGirl.create(:facility)
    end
    it "should get back all the ids" do
      results = Facility.ids_from_urls([@facility.url_name, @facility2.url_name, @facility3.url_name])
      results.should == [@facility.id, @facility2.id, @facility3.id]
    end
    it "should also work id to url" do
      results = Facility.urls_from_ids([@facility.id, @facility2.id, @facility3.id])
      results.should == [@facility.url_name, @facility2.url_name, @facility3.url_name]
    end
  end
  
end
