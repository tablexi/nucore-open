require 'spec_helper'

describe TransactionSearch do
  class TransactionSearcher < ApplicationController
    include TransactionSearch
    def params
      @params
    end
    def params=(params)
      @params = params
    end
    attr_reader :facility, :facilities, :account, :accounts, :account_owners, :products
    
  end
  before :each do
    @staff = Factory.create(:user, :username => "staff")
    UserRole.grant(@staff, UserRole::FACILITY_DIRECTOR)
    @controller = TransactionSearcher.new
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @price_group      = @authable.price_groups.create(Factory.attributes_for(:price_group))
    @account          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @staff, :created_by => @staff, :user_role => AccountUser::ACCOUNT_OWNER]])
    @order            = @staff.orders.create(Factory.attributes_for(:order, :created_by => @staff.id, :account => @account, :ordered_at => Time.now))
    @item             = @authable.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    
  end
  
  context "field populating" do
    context "with facility" do
      before :each do
        @controller.params = { :facility_id => @authable.url_name }
      end
      it "should populate facility" do
        @controller.populate_search_fields
        @controller.facility.should == @authable
        @controller.facilities.should == [@authable]
      end
      it "should populate accounts" do
        @controller.populate_search_fields
        @controller.account.should be_nil
        @controller.accounts.should == [@account]
      end
      it "should not populate an account for another facility" do
        @facility2 = Factory.create(:facility)
        @account2 = Factory.create(:credit_card_account, :account_users_attributes => [Hash[:user => @staff, :created_by => @staff, :user_role => AccountUser::ACCOUNT_OWNER]])
        
        @controller.populate_search_fields
        @controller.accounts.should == [@account]
      end
    end
    
    context "with account" do
      before :each do
        @facility2 = Factory.create(:facility)
        @credit_account = Factory.create(:credit_card_account, :facility_id => @facility2.id, :account_users_attributes => [Hash[:user => @staff, :created_by => @staff, :user_role => AccountUser::ACCOUNT_OWNER]])
        
      end
      
      it "should pull all facilities for nufs account" do
        @controller.params = { :account_id => @account.id }
        @controller.populate_search_fields
        @controller.facility.should be_nil
        @controller.facilities.should contain_all [@authable, @facility2]
      end
      it "should only have a single facility for credit card" do
        @controller.params = { :account_id => @credit_account.id }
        @controller.populate_search_fields
        @controller.facilities.should == [@facility2]
        @controller.facility.should == @facility2
      end
    end
    context "account owners" do
      before :each do
        @user2 = Factory.create(:user)
        @user3 = Factory.create(:user)
        @account2 = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user2, :created_by => @user2, :user_role => AccountUser::ACCOUNT_OWNER]])
      end
      it "should populate account owners" do
        @controller.params = { :facility_id => @authable.url_name }
        @controller.populate_search_fields
        @controller.account_owners.should contain_all [@staff, @user2]
      end
    end
    
    context "products" do
      before :each do
        @facility2 = Factory.create(:facility)
        @instrument = @authable.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
        @service = @authable.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id)) 
        @other_item = @facility2.instruments.create(Factory.attributes_for(:item))
        @controller.params = { :facility_id => @authable.url_name }
        @controller.populate_search_fields
      end
      it "should populate products" do
        @controller.products.should contain_all [@item, @instrument, @service]
      end
    end
  end
  
 
    
end