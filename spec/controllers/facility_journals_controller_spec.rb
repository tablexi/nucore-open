require 'spec_helper'
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

describe FacilityJournalsController do
  include DateHelper
  
  render_views
  
  def create_order_details
    @user=Factory.create(:user)
    @order_detail1 = place_and_complete_item_order(@user, @authable, @account, true)
    @order_detail2 = place_and_complete_item_order(@user, @authable, @account)
  
    @account2=Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']], :facility_id => @authable.id)
    @authable_account2 = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @order_detail3 = place_and_complete_item_order(@user, @authable, @account2, true)
    
    [@order_detail1, @order_detail3].each do |od|
      od.reviewed_at = 1.day.ago
      od.save!
    end
  
  end

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @admin, :created_by => @admin, :user_role => 'Owner']], :facility_id => @authable.id)
    @journal=Factory.create(:journal, :facility => @authable, :created_by => @admin.id, :journal_date => Time.zone.now)
  end


  context 'index' do
    before :each do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
      @pending_journal=Factory.create(:journal, :facility => @authable, :created_by => @admin.id, :journal_date => Time.zone.now, :is_successful => nil)
    end

    it_should_allow_managers_only do
      response.should be_success
      assigns(:pending_journal).should == @pending_journal
    end
  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
      @params={ :facility_id => @authable.url_name, :id => @journal.id }
    end

    it_should_allow_managers_only

  end


  context 'create' do

    before :each do
      @method=:post
      @action=:create
      @journal_date=DateTime.now.strftime('%m/%d/%Y')
      @params={
        :facility_id => @authable.url_name,
        :journal_date => @journal_date
      }
    end

    it_should_allow_managers_only :redirect, 'and respond gracefully when no order details given' do |user|
      journal_date=parse_usa_date(@journal_date)
      flash[:error].should_not be_nil
    end


    context 'with order detail' do

      before :each do
        acct=create_nufs_account_with_owner :director
        place_and_complete_item_order(@director, @authable, acct)
        define_open_account(@item.account, acct.account_number)
        @params.merge!(:order_detail_ids => [ @order_detail.id ])
      end

      it_should_allow :director do
        assigns(:journal).errors.should be_empty
        assigns(:journal).should_not be_new_record
        assigns(:journal).created_by.should == @director.id
        assigns(:journal).journal_date.should == parse_usa_date(@journal_date)
        assigns(:journal).journal_rows.should_not be_empty
        should set_the_flash
        assert_redirected_to facility_journals_path
      end

    end
    
    context "searching" do
      before :each do
        @user = @admin
      end
      it_should_support_searching
    end

  end


  context 'show' do

    before :each do
      @method=:get
      @action=:show
      @params={ :facility_id => @authable.url_name, :id => @journal.id }
    end

    it_should_allow_managers_only

  end
  
  context 'new' do
    before :each do
      @method = :get
      @action=:new
      @params = { :facility_id => @authable.url_name }
      create_order_details
    end
    
    it_should_allow_managers_only do
      response.should be_success
    end
    
    it "should set appropriate values" do
      sign_in @admin
      do_request
      response.should be_success
      assigns(:order_details).should be_include(@order_detail1)
      assigns(:order_details).should be_include(@order_detail3)
      assigns(:pending_journal).should be_nil
      assigns(:order_detail_action).should == :create
    end
    
    it "should not have different values if there is a pending journal" do
      @pending_journal = Factory.create(:journal, :facility_id => @authable.id, :created_by => @admin.id, :journal_date => Time.zone.now, :is_successful => nil)
      sign_in @admin
      do_request
      assigns(:order_details).should contain_all [@order_detail1, @order_detail3]
      assigns(:pending_journal).should == @pending_journal
      assigns(:order_detail_action).should be_nil
    end
    
    context "searching" do
      before :each do
        @user = @admin
      end
      it_should_support_searching
    end
  end

end