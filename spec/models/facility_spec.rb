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
      @factory1 = Factory.create(:facility)
      @factory2 = Factory.build(:facility, :url_name => @factory1.url_name)
      @factory2.should_not be_valid
    end
  end
end
