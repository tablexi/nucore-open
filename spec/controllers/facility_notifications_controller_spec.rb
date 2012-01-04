require 'spec_helper'
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

describe FacilityNotificationsController do
  
  before(:all) { create_users }
  
  before :each do
    @authable=Factory.create(:facility)
    @user=Factory.create(:user)
    @account=Factory.create(:credit_card_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @authable_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @params={ :facility_id => @authable.url_name }
    
    @order_detail1 = place_and_complete_item_order(@user, @authable, @account)
    @order_detail2 = place_and_complete_item_order(@user, @authable, @account)
    
    @account2=Factory.create(:credit_card_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @authable_account2 = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @order_detail3 = place_and_complete_item_order(@user, @authable, @account2)
  end
  
  context "index" do
    before :each do
      @method=:get
      @action=:index
    end

    it_should_allow_managers_only do
      (assigns(:order_details) - [@order_detail1, @order_detail2, @order_detail3]).should be_empty
      assigns(:order_detail_action).should == :send_notifications
      should_not set_the_flash
    end
    
    context "searching" do
      before :each do 
        @user = @admin
      end
      it_should_support_searching
    end
  end
  
  context "send_notifications" do
    before :each do
      @method=:post
      @action=:send_notifications
      @params.merge!({ :order_detail_ids => [@order_detail1.id, @order_detail2.id] })
    end
    
    it_should_allow_managers_only :redirect do
      assigns(:errors).should be_empty
      assigns(:accounts_to_notify).should == [@account]
      assigns(:orders_notified).should == [@order_detail1, @order_detail2]
      @order_detail1.reload.reviewed_at.should_not be_nil
      @order_detail1.reviewed_at.should > 6.days.from_now
    end
       
    context "multiple accounts" do
      before :each do
        @params.merge!({:order_detail_ids => [@order_detail1.id, @order_detail2.id, @order_detail3.id] })
      end
      
      it_should_allow_managers_only :redirect do
        assigns(:errors).should be_empty
        assigns(:orders_notified).should == [@order_detail1, @order_detail2, @order_detail3]
        assigns(:accounts_to_notify).should == [@account, @account2]
      end
    end
    
    context "errors" do
      it "should display an error for no orders" do
        @params[:order_detail_ids] = nil
        maybe_grant_always_sign_in(:admin)
        do_request
        flash[:error].should_not be_nil
        response.should be_redirect
      end
    end
  end
  
  context "in review" do
     before :each do
      @method=:get
      @action=:in_review
      @order_detail1.reviewed_at = 7.days.from_now
      @order_detail1.save!
      @order_detail3.reviewed_at = 7.days.from_now
      @order_detail3.save!
    end

    it_should_allow_managers_only do
      (assigns(:order_details) - [@order_detail1, @order_detail3]).should be_empty
      assigns(:order_detail_action).should == :mark_as_reviewed
      should_not set_the_flash
    end
    
    context "searching" do
      before :each do
        @user = @admin
      end
      it_should_support_searching
    end
  end
  
  context "mark as reviewed" do
    before :each do
      @method = :post
      @action = :mark_as_reviewed
      maybe_grant_always_sign_in(:admin)
    end
    
    it "should update" do
      Timecop.freeze do
        @params.merge!({:order_detail_ids => [@order_detail1.id, @order_detail3.id]})
        do_request
        flash[:error].should be_nil
        assigns(:order_details_updated).should == [@order_detail1, @order_detail3]
        @order_detail1.reload.reviewed_at.should == Time.zone.now
        @order_detail3.reload.reviewed_at.should == Time.zone.now
      end
    end
    
    it "should display an error for no orders" do
      do_request
      flash[:error].should_not be_nil
    end
  end
  
  
end
