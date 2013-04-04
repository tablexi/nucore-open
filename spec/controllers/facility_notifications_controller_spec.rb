require 'spec_helper'
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

describe FacilityNotificationsController do

  before(:all) { create_users }
  render_views

  before :each do
    Settings.billing.review_period = 7.days
    @authable=FactoryGirl.create(:facility)
    @user=FactoryGirl.create(:user)
    @account=FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @authable_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @params={ :facility_id => @authable.url_name }

    @order_detail1 = place_and_complete_item_order(@user, @authable, @account)
    @order_detail2 = place_and_complete_item_order(@user, @authable, @account)

    @account2=FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @authable_account2 = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @order_detail3 = place_and_complete_item_order(@user, @authable, @account2)
  end
  after :each do
    Settings.reload!
  end
  def self.it_should_404_for_zero_day_review
    it 'should 404 for zero day review' do
      Settings.billing.review_period = 0.days
      sign_in @admin
      do_request
      response.code.should == "404"
    end
  end


  context "index" do
    before :each do
      @method=:get
      @action=:index
    end
    it_should_deny_all [:staff, :senior_staff]
    it_should_404_for_zero_day_review

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

    it_should_404_for_zero_day_review

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_managers_only :redirect do
      assigns(:errors).should be_empty
      assigns(:accounts_to_notify).should == [[@account, @authable]]
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
        assigns(:accounts_to_notify).should == [[@account, @authable], [@account2, @authable]]
      end

      context 'while signed in' do
        before :each do
          maybe_grant_always_sign_in(:admin)
        end

        it 'should display the account list if less than 10 accounts' do
          @accounts = FactoryGirl.create_list(:nufs_account, 3, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
          @authable_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
          @params={ :facility_id => @authable.url_name }

          @order_details = @accounts.map do |account|
            place_and_complete_item_order(@user, @authable, account)
          end

          @params.merge!(:order_detail_ids => @order_details.map(&:id))
          do_request
          should set_the_flash
          @accounts.should be_all { |account| flash[:notice].include? account.account_number }
        end

        it 'should display a count if more than 10 accounts notified' do
          @accounts = FactoryGirl.create_list(:nufs_account, 11, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
          @authable_account = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
          @params={ :facility_id => @authable.url_name }

          @order_details = @accounts.map do |account|
            place_and_complete_item_order(@user, @authable, account)
          end

          @params.merge!(:order_detail_ids => @order_details.map(&:id))
          do_request
          should set_the_flash
          flash[:notice].should include "11 accounts"
        end
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

    it_should_deny_all [:staff, :senior_staff]
    it_should_404_for_zero_day_review

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

    it_should_deny_all [:staff, :senior_staff]
    it_should_404_for_zero_day_review

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
