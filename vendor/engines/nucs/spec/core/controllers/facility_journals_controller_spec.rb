require 'spec_helper'
require 'controller_spec_helper'
require 'transaction_search_spec_helper'

describe FacilityJournalsController do
  include DateHelper
  
  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @account = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @admin, :created_by => @admin, :user_role => 'Owner']], :facility_id => @authable.id)
    @journal=Factory.create(:journal, :facility => @authable, :created_by => @admin.id, :journal_date => Time.zone.now)
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

  end

end