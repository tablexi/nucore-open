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
        do_request
        response.should be_success
      end
      it 'should set products' do
        assigns[:products].should contain_all [@item, @service, @instrument]
      end
      it 'should set search types' do
        assigns[:search_types].should_not be_empty
      end
    end
  end

  context "create" do
    before :each do
      @action = 'create'
      @method = :post
    end
    it_should_require_login
    it_should_allow_managers_only {}

    context 'authorized' do
      before :each do
        maybe_grant_always_sign_in :director
      end
      context 'empty params' do
        before :each do
         do_request
        end
        it 'should set products' do
          assigns[:products].should contain_all [@item, @service, @instrument]
        end
        it 'should set search types' do
          assigns[:search_types].should_not be_empty
        end
      end
    end
  end


    
end