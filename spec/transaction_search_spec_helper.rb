def it_should_support_searching(date_range_field=:fulfilled_at)
  context "searching" do
    before :each do
      sign_in @user
      @sql_datetime_format = '%Y-%m-%d %H:%M:%S'
      @date_string = '2001-01-01'
      @datetime = Time.zone.parse(@date_string)
    end
    it "should support the inner method" do
      controller.should respond_to :"#{@action}_with_search"
    end

   it "should take start date" do
      @params.merge!({:start_date => @date_string})
      do_request
      assigns[:order_details].should contain_beginning_of_day(date_range_field, @datetime)
    end

    it "should take end date" do
      @params.merge!({:end_date => @date_string})
      do_request
      assigns[:order_details].should contain_end_of_day(date_range_field, @datetime)
    end
    it "should take facilities" do
      @params.merge!({:facilities => [2, 3]})
      do_request
      assigns[:order_details].where_values.should be_include("orders.facility_id in (2,3)")
    end

    it "should take accounts" do
      @params.merge!({:accounts => [1,6]})
      do_request
      assigns[:order_details].where_values.should be_include("order_details.account_id in (1,6)")
    end

    it "should take products" do
      @params.merge!({:products => [2,4]})
      do_request
      assigns[:order_details].where_values.should be_include("order_details.product_id in (2,4)")
    end

    it "should handle account owners" do
      @params.merge!({:account_owners => [3,4]})
      do_request
      assigns[:order_details].where_values.should be_include("account_users.user_id in (3,4)")
    end

    it "should handle order statuses" do
      @params.merge!({:order_statuses => [1,2]})
      do_request
      assigns[:order_details].where_values.should be_include("order_details.order_status_id in (1,2)")
    end
  end
end