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
    # make sure order detail 2 is not reviewed (it is if a zero day review period)
    @order_detail2.update_attributes(:reviewed_at => nil)
    
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

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_managers_only do
      response.should be_success
      assigns(:pending_journals).should == [@pending_journal]
    end
  end


  context 'update' do

    before :each do
      @method=:put
      @action=:update
      @params={ :facility_id => @authable.url_name, :id => @journal.id, :journal => {:reference => 'REFERENCE NUMBER' } }
      @journal.update_attribute(:is_successful, nil)
    end

    it_should_allow_managers_only {}
    it_should_deny_all [:staff, :senior_staff]

    context 'signed in' do
      before :each do
        grant_and_sign_in @director
        create_order_details
        # Don't worry about account validation in these tests
        Settings.validator.class_name.constantize.any_instance.stubs(:account_is_open!).returns(true)
        @creation_errors = @journal.create_journal_rows!([@order_detail1, @order_detail3])
      end
      it 'should have been set up properly' do
        @creation_errors.should be_empty
        @order_detail1.reload.journal_id.should_not be_nil
        @order_detail3.reload.journal_id.should_not be_nil
        @journal.order_details.uniq.size.should == 2
        @journal.is_successful.should be_nil
      end

      it 'should show an error if journal_status is blank' do
        do_request
        flash[:error].should include 'Please select a journal status'
      end
      it 'should throw an error if :reference is empty' do
        @params[:journal_status] = 'succeeded'
        @params[:journal].delete :reference
        do_request
        flash[:error].should include "Reference may not be blank"
      end
      it 'should leave success as nil' do
        do_request
        @journal.reload.is_successful.should be_nil
      end

      context 'successful journal' do
        before :each do
          @params.merge!({:journal_status => 'succeeded'})
          do_request
        end
        it 'should not have any errors' do
          assigns[:journal].errors.should be_empty
          flash[:error].should be_nil
        end
        it 'should set the updated by to the logged in user and leave created by alone' do
          assigns[:journal].updated_by.should == @director.id
          assigns[:journal].created_by.should == @admin.id
        end
        it 'should have an is_successful value of true' do
          assigns[:journal].is_successful? == true
        end
        it 'should set all the order details to reconciled' do
          reconciled_status = OrderStatus.reconciled.first
          @order_detail1.reload.order_status.should == reconciled_status
          @order_detail3.reload.order_status.should == reconciled_status
        end
      end

      context 'successful with errors' do
        before :each do
          @params.merge!({:journal_status => 'succeeded_errors'})
          do_request
        end
        it 'should not have any errors' do
          assigns[:pending_journal].errors.should be_empty
          flash[:error].should be_nil
        end
        it 'should set the updated by to the logged in user and leave created by alone' do
          assigns[:journal].updated_by.should == @director.id
          assigns[:journal].created_by.should == @admin.id
        end
        it 'should have an is_successful value of true' do
          assigns[:journal].is_successful == true
        end
        it 'should leave the orders as complete' do
          completed_status = OrderStatus.complete.first
          @order_detail1.reload.order_status.should == completed_status
          @order_detail3.reload.order_status.should == completed_status
        end
      end

      context 'failed journal' do
        before :each do
          @params.merge!({:journal_status => 'failed'})
          do_request
        end
        it 'should not have any errors' do
          assigns[:journal].errors.should be_empty
          flash[:error].should be_nil
        end
        it 'should set the updated by to the logged in user and leave created by alone' do
          assigns[:journal].updated_by.should == @director.id
          assigns[:journal].created_by.should == @admin.id
        end
        it 'should have a successful value of false' do
          assigns[:journal].is_successful.should_not be_nil
          assigns[:journal].is_successful.should == false
          # make sure it's really false, even in the database
          @journal.reload.is_successful.should_not be_nil
          @journal.reload.is_successful.should == false
        end
        it 'should set all journal ids to nil for all order_details in a failed journal' do
          @order_detail1.reload.journal_id.should be_nil
          @order_detail3.reload.journal_id.should be_nil
        end
      end
    end

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

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_managers_only :redirect, 'and respond gracefully when no order details given' do |user|
      journal_date=parse_usa_date(@journal_date)
      flash[:error].should_not be_nil
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
    it_should_deny_all [:staff, :senior_staff]

  end
  
  context 'new' do
    before :each do
      @method = :get
      @action=:new
      @params = { :facility_id => @authable.url_name }
      create_order_details
    end
    
    it_should_deny_all [:staff, :senior_staff]
    
    it_should_allow_managers_only do
      response.should be_success
    end
    
    it "should set appropriate values" do
      sign_in @admin
      do_request
      response.should be_success
      assigns(:order_details).should be_include(@order_detail1)
      assigns(:order_details).should be_include(@order_detail3)
      assigns(:pending_journals).should be_empty
      assigns(:order_detail_action).should == :create
    end
    
    it "should not have different values if there is a pending journal" do
      
      # create and populate a journal
      @pending_journal = Factory.create(:journal, :facility_id => @authable.id, :created_by => @admin.id, :journal_date => Time.zone.now, :is_successful => nil)
      @order_detail4 = place_and_complete_item_order(@user, @authable, @account)

      @pending_journal.create_journal_rows!([@order_detail4])

      sign_in @admin
      do_request
      assigns(:order_details).should contain_all [@order_detail1, @order_detail3]
      assigns(:pending_journals).should == [@pending_journal]
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
