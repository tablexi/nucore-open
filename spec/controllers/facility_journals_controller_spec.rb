require 'spec_helper'
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

describe FacilityJournalsController do
  include DateHelper

  render_views

  def create_order_details
    @user=FactoryGirl.create(:user)
    @order_detail1 = place_and_complete_item_order(@user, @authable, @account, true)
    @order_detail2 = place_and_complete_item_order(@user, @authable, @account)
    # make sure order detail 2 is not reviewed (it is if a zero day review period)
    @order_detail2.update_attributes(:reviewed_at => nil)

    @account2=FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @user), :facility_id => @authable.id)
    @authable_account2 = @authable.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @order_detail3 = place_and_complete_item_order(@user, @authable, @account2, true)

    [@order_detail1, @order_detail3].each do |od|
      od.reviewed_at = 1.day.ago
      od.save!
    end

  end

  before(:all) { create_users }

  before(:each) do
    @authable=FactoryGirl.create(:facility)
    @account = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @admin), :facility_id => @authable.id)
    @journal=FactoryGirl.create(:journal, :facility => @authable, :created_by => @admin.id, :journal_date => Time.zone.now)
  end

  context 'index' do
    before :each do
      @method=:get
      @action=:index
      @params={ :facility_id => @authable.url_name }
      @pending_journal=FactoryGirl.create(:journal, :facility => @authable, :created_by => @admin.id, :journal_date => Time.zone.now, :is_successful => nil)
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
        Settings.validator.class_name.constantize.any_instance.stub(:account_is_open!).and_return(true)
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

    context 'validations' do
      shared_examples_for 'journal error' do |error_message|
        before :each do
          do_request
        end
        it 'should not create a journal' do
          expect(assigns(:journal)).to be_new_record
        end

        it 'has an error' do
          expect(assigns(:journal).errors.full_messages.join).to include error_message
        end
      end

      before :each do
        create_order_details
        @params[:order_detail_ids] = [@order_detail1.id, @order_detail3.id]
        sign_in @admin
      end

      context 'order detail is already journaled' do
        before :each do
          @params[:order_detail_ids] = [@order_detail1.id]
          @order_detail1.update_attributes(:journal_id => 1)
        end

        it_behaves_like 'journal error', "is already journaled in journal"
      end

      context 'spans fiscal year' do
        before :each do
          @order_detail1.update_attributes(:fulfilled_at => SettingsHelper::fiscal_year_end - 1.day)
          @order_detail3.update_attributes(:fulfilled_at => SettingsHelper::fiscal_year_end + 1.day)
        end

        it_behaves_like 'journal error', "Journals may not span multiple fiscal years."
      end

      context 'trying to journal in the future' do
        before :each do
          @params[:journal_date] = format_usa_date(1.day.from_now)
        end

        it_behaves_like 'journal error', "Journal date may not be in the future"
      end

      context 'trying to put journal date before fulfillment date' do
        before :each do
          @order_detail1.update_attributes(:fulfilled_at => 5.days.ago)
          @order_detail3.update_attributes(:fulfilled_at => 3.days.ago)
          @params[:journal_date] = format_usa_date(4.days.ago)
        end

        it_behaves_like 'journal error', "Journal date may not be before the latest fulfillment date."

        it 'does allow to be the same day' do
          @params[:journal_date] = format_usa_date(3.day.ago)
          do_request
          expect(assigns(:journal)).to be_persisted
        end
      end
    end

    context "searching" do
      before :each do
        @user = @admin
      end
      it_should_support_searching
    end

    context 'with a mixed facility journal' do
      before :each do
        create_order_details

        @facility2 = FactoryGirl.create(:facility)
        @account2 = FactoryGirl.create(:nufs_account, :account_users_attributes => account_users_attributes_hash(:user => @admin), :facility_id => @facility2.id)
        @facility2_order_detail = place_and_complete_item_order(@user, @facility2, @account2, true)

        @params[:facility_id] = 'all'
        @params[:order_detail_ids] = [@order_detail1.id, @facility2_order_detail.id]
        sign_in @admin
        do_request
      end

      it 'should set the facility id to nil' do
        expect(assigns(:journal).facility_id).to be_nil
      end
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
      @pending_journal = FactoryGirl.create(:journal, :facility_id => @authable.id, :created_by => @admin.id, :journal_date => Time.zone.now, :is_successful => nil)
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
