require 'spec_helper'
require 'controller_spec_helper'

describe TransactionHistoryController do
  
  before(:all) { create_users }
  
  before :each do
    @controller = TransactionHistoryController.new
    
    @authable         = Factory.create(:facility)
    @facility_account = @authable.facility_accounts.create(Factory.attributes_for(:facility_account))
    @price_group      = @authable.price_groups.create(Factory.attributes_for(:price_group))
    @account          = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @staff, :created_by => @staff, :user_role => AccountUser::ACCOUNT_OWNER]])
    @order            = @staff.orders.create(Factory.attributes_for(:order, :created_by => @staff.id, :account => @account, :ordered_at => Time.now))
    @item             = @authable.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
  end
  
  context "do_search" do
    before :each do
      @order_detail3 = Factory.create(:order_detail, :order => @order, :fulfilled_at => 1.hour.ago, :product => @item, :account => @account)
      @order_detail2 = Factory.create(:order_detail, :order => @order, :fulfilled_at => Time.zone.now, :product => @item, :account => @account)
      @order_detail1 = Factory.create(:order_detail, :order => @order, :fulfilled_at => nil, :product => @item, :account => @account)
    end
      
    it "should return nils first" do
      
      order_details = @controller.send(:do_search, { :accounts => [@account.id] })
      order_details.map(&:id).should == [@order_detail1, @order_detail2, @order_detail3].map(&:id)
    end
    
  end
  
end
