require 'spec_helper'
require 'controller_spec_helper'

describe BulkEmailController do
  render_views

  before(:all) { create_users }

  before :each do
    @authable = Factory.create(:facility)
    @facility_account = Factory.create(:facility_account, :facility => @authable)
    @item = @authable.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    @service = @authable.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
    @instrument = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @params={ :facility_id => @authable.url_name }
  end

  context "new" do
    before :each do
      @action = 'new'
      @method = :get
    end
    
    it_should_require_login
    it_should_allow_managers_only {}

    context 'authorized' do
      before :each do
        maybe_grant_always_sign_in :director
      end
      context 'parameter settings' do
        before :each do
          do_request
          response.should be_success
        end
        it 'should set products' do
          assigns[:products].should contain_all [@item, @service, @instrument]
        end
        it 'should set the products in order' do
          assigns[:products].should == [@item, @service, @instrument].sort
        end
        it 'should set search types' do
          assigns[:search_types].should_not be_empty
        end
        it 'should set the search types in order' do
          assigns[:search_types].keys.should == [:customers, :account_owners, :customers_and_account_owners, :authorized_users]
        end
        it 'should have the facility_id as the id, not the url_name' do
          assigns[:search_fields][:facility_id].should == @authable.id
        end
      end
      context 'product loading' do
        it 'should include hidden products' do
          @item = @authable.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id, :is_hidden => true))
          do_request
          response.should be_success
          assigns[:products].should be_include @item
        end
        it 'should not include archived products' do
          @item = @authable.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id, :is_archived => true))
          do_request
          response.should be_success
          assigns[:products].should_not be_include @item
        end
      end
    end
    
  end

  context "search" do
    before :each do
      @action = 'search'
      @method = :post
      @params.merge!({ :search_type => :customers })
    end
    it_should_require_login
    it_should_allow_managers_only {}

    context 'authorized' do
      before :each do
        maybe_grant_always_sign_in :director
      end

      it 'should set the search method to customer if no search method' do
        @params.delete :search_type
        do_request
        assigns[:search_fields][:search_type].should == :customers   
      end
      
      before :each do
       do_request
      end
      it 'should set products' do
        assigns[:products].should contain_all [@item, @service, @instrument]
      end
      it 'should set search types' do
        assigns[:search_types].should_not be_empty
      end
      it 'should have the facility_id as the id, not the url_name' do
        assigns[:search_fields][:facility_id].should == @authable.id
      end
    end
    
    context "pagination" do
      before :each do
        maybe_grant_always_sign_in :director
      end
      it "should paginate for html" do
        do_request
        assigns[:users].should be_respond_to :per_page
      end

      context "csv" do
        before :each do
          @params.merge!({:format => 'csv'})
        end
        it "should not paginate" do
          do_request
          assigns[:users].should_not be_respond_to :per_page
        end
      end
    end
    
  end
end