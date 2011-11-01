require 'spec_helper'

describe TransactionHistoryController do
  before :each do
    @controller = TransactionHistoryController.new
    @facility = Factory.create(:facility, :url_name => "ffw")
    @facility2 = Factory.create(:facility, :url_name => "ttw")
    @facility3 = Factory.create(:facility, :url_name => "ibcflow")
  end
  context "extract parameters" do
    
    it "should extract parameters properly with an account" do
      @result1 = @controller.extract_parameters("12-14/#{@facility.url_name}/all/all")
      @result1[:accounts].should == ["12", "14"]
      @result1[:facilities].sort.should == [@facility.id]
      @result1[:start_date].should be_nil
      @result1[:end_date].should be_nil
      
      @result2 = @controller.extract_parameters("12-14/#{@facility.url_name}-#{@facility2.url_name}/all/all")

      @result2[:accounts].should == ["12", "14"]
      @result2[:facilities].sort.should == [@facility.id, @facility2.id]
      @result2[:start_date].should be_nil
      @result2[:end_date].should be_nil
    end
    it "should extract parameters without an account" do
      @result3 = @controller.extract_parameters("#{@facility.url_name}-#{@facility2.url_name}/04-05-2011/all")
      @result3[:accounts].should be_nil
      @result3[:facilities].sort.should == [@facility.id, @facility2.id]
      @result3[:start_date].should == "04-05-2011"
      @result3[:end_date].should be_nil
      
      @result4 = @controller.extract_parameters("#{@facility3.url_name}/01-02-2010/01-30-2011")
      @result4[:accounts].should be_nil
      @result4[:facilities].sort.should == [@facility3.id]
      @result4[:start_date].should == "01-02-2010"
      @result4[:end_date].should == "01-30-2011"
    end
    
    it "should handle 'all' facility name" do
      @result4 = @controller.extract_parameters("12/all/01-01-2010/02-01-2010")
      @result4[:accounts].should == ["12"]
      @result4[:facilities].should be_nil
      
      @result5 = @controller.extract_parameters("all/01-01-2010/02-01-2010")
      @result5[:accounts].should be_nil
      @result5[:facilities].should be_nil
    end
    
    it "should throw a page not found for invalid parameters" do
      expect { @controller.extract_parameters("ibc/xxx/xxx") }.to raise_error(ActionController::RoutingError)
    end    
  end
  
  context "combine parameters" do
    it "should handle some empty strings" do
      @result = @controller.combine_parameters({:accounts => [1], :start_date => "", :end_date => ""})
      @result.should == "1/all/all/all"
    end
    
    it "should join things back the way they came from" do
      @urls = ["12-14/#{@facility.url_name}/all/all",
               "12-14/#{@facility.url_name}-#{@facility2.url_name}/all/all", 
                "#{@facility.url_name}-#{@facility2.url_name}/04-05-2011/all",
                "#{@facility3.url_name}/01-02-2010/01-30-2011",
                "12/all/01-01-2010/02-01-2010",
                "all/01-01-2010/02-01-2010"]
      @urls.each do |url|
        @result = @controller.extract_parameters(url)
        @result.should_not be_nil
        @controller.combine_parameters(@result).should == url
      end      
    end
  end
end
