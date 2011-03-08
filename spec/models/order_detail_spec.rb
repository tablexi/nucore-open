require 'spec_helper'

describe OrderDetail do

  it "should create using factory, with order status and state of 'new', with defaut version of 1" do
    @facility     = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @user         = Factory.create(:user)
    @item         = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    @item.should be_valid
    @account      = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @order        = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
    @order.should be_valid
    @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
    @order_detail.should be_valid
    @order_detail.order_status.name.should == 'New'
    @order_detail.state.should == 'new'
    @order_detail.version.should == 1
  end

  it "should have a product" do
    should_not allow_value(nil).for(:product_id)
  end

  it "should have a order" do
    should_not allow_value(nil).for(:order_id)
  end

  it "should have a quantity of at least 1" do
    should_not allow_value(0).for(:quantity)
    should_not allow_value(nil).for(:quantity)
    should allow_value(1).for(:quantity)
  end

  context "update account" do
    it "should set the account id"
    it "should set the actual cost for items and services"
    it "should set the estimated cost for instruments"
    it "should set the price policy"
    it "should set costs to nil if there is no valid price policy"
    it "should set the price policy to nil if there is no valid price policy"
  end

  context "item purchase validation" do
    before(:each) do
      @facility       = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user           = Factory.create(:user)
      @account        = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @price_group    = Factory.create(:price_group, :facility => @facility)
      @pg_user_member = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @order          = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
      @item           = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @item_pp        = @item.item_price_policies.create(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id))
      @order_detail   = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
      @order_detail.update_attributes(:actual_cost => 20, :actual_subsidy => 10, :price_policy_id => @item_pp.id)
    end

    it "should be valid for an item purchase with valid attributes" do
      define_open_account(@order_detail.product.account, @order_detail.account.account_number)
      @order_detail.valid_for_purchase?.should == true
    end

    it "should not be valid if there is no account" do
      @order_detail.update_attributes(:account_id => nil)
      @order_detail.valid_for_purchase?.should_not == true
    end

    it "should not be valid if the chart string account does not match the product account"

    it "should not be valid if there is no actual price" do
      @order_detail.update_attributes(:actual_cost => nil, :actual_subsidy => nil)
      @order_detail.valid_for_purchase?.should_not == true
    end

    it "should not be valid if a price policy is not selected" do
      @order_detail.update_attributes(:price_policy_id => nil)
      @order_detail.valid_for_purchase?.should_not == true
    end

    it "should not be valid if the user is not approved for the product" do
      @item.update_attributes(:requires_approval => true)
      @order_detail.reload # reload to update related item
      @order_detail.valid_for_purchase?.should_not == true

      ProductUser.create({:product => @item, :user => @user, :approved_by => @user.id})
      define_open_account(@order_detail.product.account, @order_detail.account.account_number)
      @order_detail.valid_for_purchase?.should == true
    end
  end

  context "service purchase validation" do
     before(:each) do
      @facility       = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user           = Factory.create(:user)
      @account        = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @price_group    = Factory.create(:price_group, :facility => @facility)
      @pg_user_member = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @order          = @user.orders.create(Factory.attributes_for(:order, :facility_id => @facility.id, :account_id => @account.id, :created_by => @user.id))
      @service        = @facility.services.create(Factory.attributes_for(:service, :facility_account_id => @facility_account.id))
      @service_pp     = @service.service_price_policies.create(Factory.attributes_for(:service_price_policy, :price_group_id => @price_group.id))
      @order_detail   = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @service.id, :account_id => @account.id))
      @order_detail.update_attributes(:actual_cost => 20, :actual_subsidy => 10, :price_policy_id => @service_pp.id)
    end

    ## TODO will need to re-write to check for surveys / file uploads
    it 'should validate for a service with no survey' do
      @order_detail.valid_service_meta?.should be true
    end

    it 'should not validate for a service with a survey and no response set' do
      @survey = Survey.create(:title => "Survey 1", :access_code => '1234')
      # add survey, make it active
      @service.surveys.push(@survey)
      @service.service_surveys.first.active!
      @order_detail.valid_service_meta?.should be false
    end

    it 'should not validate for a service with a survey and a uncompleted response set' do
      @survey = Survey.create(:title => "Survey 1", :access_code => '1234')
      # add survey, make it active, add response set
      @service.surveys.push(@survey)
      @service.service_surveys.first.active!
      @response_set = @survey.response_sets.create(:access_code => 'set1')
      @order_detail.response_set!(@response_set)
      @order_detail.valid_service_meta?.should be false
    end

    it 'should validate for a service with a survey and a completed response set' do
      @survey = Survey.create(:title => "Survey 1", :access_code => '1234')
      # add survey, make it active, add completed response set
      @service.surveys.push(@survey)
      @service.service_surveys.first.active!
      @response_set = @survey.response_sets.create(:access_code => 'set1')
      @response_set.complete!
      @response_set.save
      @order_detail.response_set!(@response_set)
      @order_detail.valid_service_meta?.should be true
    end

    it 'should not validate_extras for a service file template upload with no template results' do
      # add service file template
      @file1      = "#{Rails.root}/spec/files/template1.txt"
      @template1  = @service.file_uploads.create(:name => "Template 1", :file => File.open(@file1), :file_type => "template",
                                                 :created_by => @user)
      @order_detail.valid_service_meta?.should be false
    end

    it 'should validate_extras for a service file template upload with template results' do
      # add service file template
      @file1      = "#{Rails.root}/spec/files/template1.txt"
      @template1  = @service.file_uploads.create(:name => "Template 1", :file => File.open(@file1), :file_type => "template",
                                                 :created_by => @user)
      # add results for a specific order detail
      @results1   = @service.file_uploads.create(:name => "Results 1", :file => File.open(@file1), :file_type => "template_result",
                                                 :order_detail => @order_detail, :created_by => @user)
      @order_detail.valid_service_meta?.should be true
    end
  end

  context "instrument purchase validation" do
    it "should validate for a valid instrument with reservation"
    it "should not be valid if an instrument reservation is not valid"
    it "should not be valid if there is no estimated or actual price"
  end

  context "state management" do
    before(:each) do
      @facility = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user     = Factory.create(:user)
      @item     = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @item.should be_valid
      @account  = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order    = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
      @order.should be_valid
      @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
      @order_detail.state.should == 'new'
      @order_detail.version.should == 1
    end
    
    it "should not allow transition from 'new' to 'invoiced'" do
      @order_detail.invoice! rescue nil
      @order_detail.state.should == 'new'
      @order_detail.version.should == 1
    end
    
    it "should allow anyone to transition from 'new' to 'inprocess', increment version" do
      @order_detail.to_inprocess!
      @order_detail.state.should == 'inprocess'
      @order_detail.version.should == 2
    end

    it "should allow anyone to transition from 'inprocess' to 'reviewable', increment version" do
      @order_detail.to_inprocess!
      @order_detail.to_reviewable!
      @order_detail.state.should == 'reviewable'
      @order_detail.version.should == 3
    end

    it "should not transition from 'reviewable' to 'completed' if there is no purchase account transaction" do
      @order_detail.to_inprocess!
      @order_detail.to_reviewable!
      @order_detail.to_complete!
      @order_detail.state.should == 'reviewable'
      @order_detail.version.should == 3
    end
  end
end
