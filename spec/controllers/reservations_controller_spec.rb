require 'spec_helper'; require 'controller_spec_helper'

describe ReservationsController do
  integrate_views

  before(:all) { create_users }

  context "new, create, update" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user             = User.find_by_username(@guest.username)
      @account          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @pg_member        = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @options          = Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id,
                                                 :min_reserve_mins => 60, :max_reserve_mins => 60)
      @instrument       = @facility.instruments.create(@options)
      assert @instrument.valid?
      # add rule, available every day from 9 to 5, 60 minutes duration
      @rule             = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      # create price policy with default window of 1 day
      @price_policy     = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id))
      # create order, order detail
      @order            = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account))
      @order.add(@instrument, 1)
      @order_detail     = @order.order_details.first
    end

    it "should show calendar, with time constraints" do
      sign_in @guest
      get :new, :order_id => @order.id, :order_detail_id => @order_detail.id
      assigns[:order].should == @order
      assigns[:order_detail].should == @order_detail
      assigns[:instrument].should == @instrument
      # min date is today, max date is based on price policy window
      assigns[:min_date].should == Time.zone.now.strftime("%Y%m%d")
      assigns[:max_date].should == (Time.zone.now+1.day).strftime("%Y%m%d")
    end

    it "should create reservation for tomorrow @ 8 am for 60 minutes, set order detail price policy" do
      sign_in @guest
      post :create, :order_id => @order.id, :order_detail_id => @order_detail.id,
           :reservation => Hash[:reserve_start_date => Time.zone.now.to_date+1.day, :reserve_start_hour => '9',
                                :reserve_start_min => '0', :reserve_start_meridian => 'am', :duration_value => '60', :duration_unit => 'minutes']
      assigns[:order].should == @order
      assigns[:order_detail].should == @order_detail
      assigns[:instrument].should == @instrument
      assigns[:order_detail].price_policy.should == @price_policy
      assigns[:reservation].valid?.should == true
      # should set order detail price policy
      assigns[:order_detail].reload.price_policy.should == @price_policy
      response.should redirect_to("/orders/cart")
    end
    
    it "should update reservation" do
      # create reservation for tomorrow @ 9 am for 60 minutes, with order detail reference
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation  = @instrument.reservations.create(:reserve_start_at => @start, :order_detail => @order_detail,
                                                      :duration_value => 60, :duration_unit => 'minutes')
      assert @reservation.valid?
      # change from 9 am to 10 am
      sign_in @guest
      put :update, :order_id => @order.id, :order_detail_id => @order_detail.id, :id => @reservation.id,
                   :reservation => Hash[:reserve_start_date => @start.to_date, :reserve_start_hour => '10',
                                        :reserve_start_min => '0', :reserve_start_meridian => 'am',
                                        :duration_value => '60', :duration_unit => 'minutes']
      assigns[:order].should == @order
      assigns[:order_detail].should == @order_detail
      assigns[:instrument].should == @instrument
      assigns[:order_detail].price_policy.should == @price_policy
      assigns[:reservation].valid?.should == true
      # should update reservation time
      @reservation.reload.reserve_start_hour.should == 10
      @reservation.reload.reserve_end_hour.should == 11
      @reservation.reload.duration_mins.should == 60
    end
  end
end