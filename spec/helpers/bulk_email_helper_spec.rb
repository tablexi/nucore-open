require 'spec_helper'

describe BulkEmailHelper do
  
  # Utility class for testing the helper methods
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
    
    @purchaser = Factory.create(:user)
    @purchaser2 = Factory.create(:user)
    @purchaser3 = Factory.create(:user)

    @facility = Factory.create(:facility)
    @facility_account=Factory.create(:facility_account, :facility => @facility)
    @product=Factory.create(:item, :facility_account => @facility_account, :facility => @facility)
    @product2=Factory.create(:item, :facility_account => @facility_account, :facility => @facility)
    @product3=Factory.create(:item, :facility_account => @facility_account, :facility => @facility)

    @account = Factory.create(:nufs_account, :account_users_attributes => [ Factory.attributes_for(:account_user, :user => @owner) ])

    @controller = BulkEmailTest.new(@facility)
    @params = { :search_type => :customers }
  end

  context "search ordered dates" do
    before :each do
      @od_yesterday = place_product_order(@purchaser, @facility, @product, @account)
      @od_yesterday.order.update_attributes(:ordered_at => (Time.zone.now - 1.day))
      
      @od_tomorrow = place_product_order(@purchaser2, @facility, @product2, @account)
      @od_tomorrow.order.update_attributes(:ordered_at => (Time.zone.now + 1.day))
      
      @od_today = place_product_order(@purchaser3, @facility, @product, @account)
    end

    it "should only return the one today and the one tomorrow" do
      @params.merge!({ :order_start_date => Time.zone.now })
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@od_today, @od_tomorrow]
      users.should contain_all [@purchaser3, @purchaser2]
    end
    
    it "should only return the one today and the one yesterday" do
      @params.merge!({ :order_end_date => Time.zone.now })
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@od_yesterday, @od_today]
      users.should contain_all [@purchaser3, @purchaser]
    end

    it "should only return the one from today" do
      @params.merge!({:order_start_date => Time.zone.now, :order_end_date => Time.zone.now})
      users = @controller.do_search(@params)
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
      @params.merge!({ :reservation_start_date => Time.zone.now })
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@reservation_today.order_detail, @reservation_tomorrow.order_detail]
      users.should contain_all [@purchaser3, @purchaser2]
    end
    
    it "should only return the one today and the one yesterday" do
      @params.merge!({ :reservation_end_date => Time.zone.now })
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@reservation_yesterday.order_detail, @reservation_today.order_detail]
      users.should contain_all [@purchaser3, @purchaser]
    end

    it "should only return the one from today" do
      @params.merge!({:reservation_start_date => Time.zone.now, :reservation_end_date => Time.zone.now})
      users = @controller.do_search(@params)
      @controller.order_details.should == [@reservation_today.order_detail]
      users.should == [@purchaser3]
    end
  end

  context "search products" do
    before :each do
      @params = { :search_type => :customers }
      @od1 = place_product_order(@purchaser, @facility, @product, @account)
      @od2 = place_product_order(@purchaser2, @facility, @product2, @account)
      @od3 = place_product_order(@purchaser3, @facility, @product3, @account)
    end
    it "should return all three user details" do
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@od1, @od2, @od3]
      users.should contain_all [@purchaser, @purchaser2, @purchaser3]
    end
    it "should return just one product" do
      @params.merge!({:products => [@product.id]})
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@od1]
      users.should == [@purchaser]
    end
    it "should return two products" do
      @params.merge!({:products => [@product.id, @product2.id]})
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@od1, @od2]
      users.should contain_all [@purchaser, @purchaser2]
    end
  end

  context "search user roles" do
    before :each do
      @owner2 = Factory.create(:user)
      @owner3 = Factory.create(:user)
      @account2 = Factory.create(:nufs_account, :account_users_attributes => [ Factory.attributes_for(:account_user, :user => @owner2) ])
      @account3 = Factory.create(:nufs_account, :account_users_attributes => [ Factory.attributes_for(:account_user, :user => @owner3) ])
      
      @od1 = place_product_order(@purchaser, @facility, @product, @account)
      @od2 = place_product_order(@purchaser, @facility, @product2, @account2)
      @od3 = place_product_order(@purchaser, @facility, @product3, @account3)
      @params = {:search_type => :account_owners }
    end

    it "should find owners if no other limits" do
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@od1, @od2, @od3]
      users.map(&:id).should contain_all [@owner, @owner2, @owner3].map(&:id)
    end

    it "should find owners with limited order details" do
      @params.merge!({:products => [@product.id, @product2.id]})
      users = @controller.do_search(@params)
      @controller.order_details.should contain_all [@od1, @od2]
      users.should contain_all [@owner, @owner2]
    end

  end

  context "search authorized users" do
    before :each do
      @user = Factory.create(:user)
      @user2 = Factory.create(:user)
      @user3 = Factory.create(:user)

      @product.update_attributes(:requires_approval => true)
      @product2.update_attributes(:requires_approval => true)
      # Users 1 and 2 have access to product1
      # Users 2 and 3 have access to product2
      ProductUser.create(:product => @product, :user => @user, :approved_by => @owner.id, :approved_at => Time.zone.now)
      ProductUser.create(:product => @product, :user => @user2, :approved_by => @owner.id, :approved_at => Time.zone.now)
      ProductUser.create(:product => @product2, :user => @user2, :approved_by => @owner.id, :approved_at => Time.zone.now)
      ProductUser.create(:product => @product2, :user => @user3, :approved_by => @owner.id, :approved_at => Time.zone.now)
      @params = {:search_type => :authorized_users}
    end
    it "should return all authorized users for any instrument" do
      @params.merge!({:products => []})
      users = @controller.do_search(@params)
      users.should contain_all [@user, @user2, @user3]
    end
    it "should return only the users for a specific instrument" do
      @params.merge!({:products => [@product.id]})
      users = @controller.do_search(@params)
      users.should contain_all [@user, @user2]

      @params.merge!({:products => [@product2.id]})
      users = @controller.do_search(@params)
      users.should contain_all [@user2, @user3]
    end
  end


end