def it_should_support_searching
  context "searching" do
    before :each do
      sign_in @authable.owner.user
    end
    it "should take start date" do
      @params.merge!({:start_date => '2001-01-01'})
      do_request
      response.should be_success
      assigns[:order_details].where_values.should be_include("fulfilled_at > '2001-01-01 06:00:00'")
    end
    it "should take end date" do
      @params.merge!({:end_date => '2012-01-01'})
      do_request
      response.should be_success
      puts assigns[:order_details].where_values
      assigns[:order_details].where_values.should be_include("fulfilled_at < '2011-01-02 05:59:59'")
    end
    
    it "should take facilities"
    it "should take accounts"
    it "should take products"
  end
end