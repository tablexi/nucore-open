require 'spec_helper'

describe BulkEmailHelper do
  class BulkEmailTest
    include BulkEmailHelper
    include DateHelper
    def initialize(facility)
      @facility = facility
    end
    def current_facility
      @facility
    end
    attr_reader :order_details
  end
  before :each do
    @owner = Factory.create(:user)
    @owner2 = Factory.create(:user)
    @owner3 = Factory.create(:user)
    @business_admin = Factory.create(:user)
    @business_admin2 = Factory.create(:user)
    @purchaser = Factory.create(:user)
    @purchaser2 = Factory.create(:user)
    @purchaser3 = Factory.create(:user)

    @facility = Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @facility)
    @product=Factory.create(:item, :facility_account => @facility_account, :facility => @facility)
    @product2=Factory.create(:item, :facility_account => @facility_account, :facility => @facility)

    @account = Factory.create(:nufs_account, :account_users_attributes => [ Factory.attributes_for(:account_user, :user => @owner) ])
    @account2 = Factory.create(:nufs_account, :account_users_attributes => [ Factory.attributes_for(:account_user, :user => @owner2) ])
    @account3 = Factory.create(:nufs_account, :account_users_attributes => [ Factory.attributes_for(:account_user, :user => @owner3) ])

    @controller = BulkEmailTest.new(@facility)
  end

  context "search ordered dates" do
    before :each do
      @od_yesterday = place_item_order(@purchaser, @facility, @product, @account)
      @od_yesterday.order.update_attributes(:ordered_at => (Time.zone.now - 1.day))
      
      @od_tomorrow = place_item_order(@purchaser2, @facility, @product2, @account)
      @od_tomorrow.order.update_attributes(:ordered_at => (Time.zone.now + 1.day))
      
      @od_today = place_item_order(@purchaser3, @facility, @product, @account)
    end

    it "should only return the one today and the one tomorrow" do
      params = { :order_start_date => Time.zone.now }
      users = @controller.do_search(params)
      @controller.order_details.should contain_all [@od_today, @od_tomorrow]
      users.should contain_all [@purchaser3, @purchaser2]
    end
    
    it "should only return the one today and the one yesterday" do
      params = { :order_end_date => Time.zone.now }
      users = @controller.do_search(params)
      @controller.order_details.should contain_all [@od_yesterday, @od_today]
      users.should contain_all [@purchaser3, @purchaser]
    end

    it "should only return the one from today" do
      params = {:order_start_date => Time.zone.now, :order_end_date => Time.zone.now}
      users = @controller.do_search(params)
      @controller.order_details.should == [@od_today]
      users.should == [@purchaser3]
    end
  end

  context "search reserved dates" do
    before :each do

      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument=@facility.instruments.create(
          Factory.attributes_for(
            :instrument,
            :facility_account => @facility_account,
            :min_reserve_mins => 60,
            :max_reserve_mins => 60
          )
      )
      @reservation_yesterday = place_reservation_for_instrument(@purchaser, @instrument, @account, Time.zone.now - 1.day)
      @reservation_tomorrow = place_reservation_for_instrument(@purchaser2, @instrument, @account, Time.zone.now + 1.day)      
      @reservation_today = place_reservation_for_instrument(@purchaser3, @instrument, @account, Time.zone.now)
    end

    it "should only return the one today and the one tomorrow" do
      params = { :reservation_start_date => Time.zone.now }
      users = @controller.do_search(params)
      @controller.order_details.should contain_all [@reservation_today.order_detail, @reservation_tomorrow.order_detail]
      users.should contain_all [@purchaser3, @purchaser2]
    end
    
    it "should only return the one today and the one yesterday" do
      params = { :reservation_end_date => Time.zone.now }
      users = @controller.do_search(params)
      @controller.order_details.should contain_all [@reservation_yesterday.order_detail, @reservation_today.order_detail]
      users.should contain_all [@purchaser3, @purchaser]
    end

    it "should only return the one from today" do
      params = {:reservation_start_date => Time.zone.now, :reservation_end_date => Time.zone.now}
      users = @controller.do_search(params)
      @controller.order_details.should == [@reservation_today.order_detail]
      users.should == [@purchaser3]
    end
  end

  context "search products" do
    before :each do
      #place orders
    end
    it "should return all products"
    it "should return just one product"
    it "should return two products"
  end

  context "search user roles" do
    it "should search the user roles"
  end

  context "search authorized users" do
    it "should return all authorized users"
  end


end