require "rails_helper"
require 'controller_spec_helper'

RSpec.describe BulkEmailController do
  render_views

  before(:all) { create_users }

  before :each do
    @authable = FactoryGirl.create(:facility)
    @facility_account = FactoryGirl.create(:facility_account, :facility => @authable)
    @item = @authable.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
    @service = @authable.services.create(FactoryGirl.attributes_for(:service, :facility_account_id => @facility_account.id))
    @instrument = FactoryGirl.create(:instrument, :facility => @authable, :facility_account_id => @facility_account.id)
    @restricted_item = @authable.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id, :requires_approval => true))
    @params={ :facility_id => @authable.url_name }
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

      it "users should be not nil if there is a search type" do
        do_request
        expect(assigns[:users]).not_to be_nil
      end
      it "@users should be nil if there is no search type" do
        @params.delete(:search_type)
        do_request
        expect(assigns[:users]).to be_nil
      end
      context 'parameter settings' do
        before :each do
          do_request
          expect(response).to be_success
        end
        it 'should set products' do
          expect(assigns[:products]).to contain_all [@item, @service, @instrument, @restricted_item]
        end
        it 'should set the products in order' do
          expect(assigns[:products]).to eq([@item, @service, @instrument, @restricted_item].sort)
        end
        it 'should set search types' do
          expect(assigns[:search_types]).not_to be_empty
        end
        it 'should set the search types in order' do
          expect(assigns[:search_types].keys).to eq([:customers, :account_owners, :customers_and_account_owners, :authorized_users])
        end
        it 'should have the facility_id as the id, not the url_name' do
          expect(assigns[:search_fields][:facility_id]).to eq(@authable.id)
        end
        it 'should not have :authorized_users if there are no restricted instruments' do
          @restricted_item.destroy
          do_request
          expect(assigns[:search_types]).not_to be_include :authorized_users
        end
      end
      context 'product loading' do
        it 'should include hidden products' do
          @item = @authable.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id, :is_hidden => true))
          do_request
          expect(response).to be_success
          expect(assigns[:products]).to be_include @item
        end
        it 'should not include archived products' do
          @item = @authable.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id, :is_archived => true))
          do_request
          expect(response).to be_success
          expect(assigns[:products]).not_to be_include @item
        end

      end

    end

    context "pagination" do
      before :each do
        maybe_grant_always_sign_in :director
      end
      it "should paginate for html" do
        do_request
        expect(assigns[:users]).to be_respond_to :per_page
      end

      context "csv" do
        before :each do
          @params.merge!({:format => 'csv'})
        end
        it "should not paginate" do
          do_request
          expect(assigns[:users]).not_to be_respond_to :per_page
        end
        it 'should set the filename in the content disposition' do
          do_request
          expect(response.headers['Content-Disposition']).to eq("attachment; filename=\"bulk_email_customers.csv\"")
        end
      end
    end
  end
end
