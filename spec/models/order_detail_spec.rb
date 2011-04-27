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
    before(:each) do
      @facility = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user     = Factory.create(:user)
      @item     = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
      @account  = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order    = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
      @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
      @price_group = Factory.create(:price_group, :facility => @facility)
      Factory.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
      UserPriceGroupMember.create!(:price_group => @price_group, :user => @user)
      @pp=Factory.create(:item_price_policy, :item => @item, :price_group => @price_group)
    end

    it 'should set estimated costs and assign account' do
      @order_detail.update_account(@account)
      @order_detail.account.should == @account
      costs=@pp.estimate_cost_and_subsidy(@order_detail.quantity)
      @order_detail.estimated_cost.should == costs[:cost]
      @order_detail.estimated_subsidy.should == costs[:subsidy]
      @order_detail.should be_cost_estimated
    end
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

    it "should not be valid if there is no account" do
      @order_detail.update_attributes(:account_id => nil)
      @order_detail.valid_for_purchase?.should_not == true
    end

    it "should not be valid if the chart string account does not match the product account"

    context 'needs open account' do
      before :each do
        Factory.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
        define_open_account(@order_detail.product.account, @order_detail.account.account_number)
      end

      it "should be valid for an item purchase with valid attributes" do
        @order_detail.valid_for_purchase?.should == true
      end

      it "should be valid if there is no actual price" do
        @order_detail.update_attributes(:actual_cost => nil, :actual_subsidy => nil)
        @order_detail.valid_for_purchase?.should == true
      end

      it "should be valid if a price policy is not selected" do
        @order_detail.update_attributes(:price_policy_id => nil)
        @order_detail.valid_for_purchase?.should == true
      end

      it "should not be valid if the user is not approved for the product" do
        @item.update_attributes(:requires_approval => true)
        @order_detail.reload # reload to update related item
        @order_detail.valid_for_purchase?.should_not == true
        ProductUser.create({:product => @item, :user => @user, :approved_by => @user.id})
        @order_detail.valid_for_purchase?.should == true
      end
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

  context 'instrument' do

#    before :each do
#      @facility       = Factory.create(:facility)
#      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
#      @user           = Factory.create(:user)
#      @account        = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
#      @price_group    = Factory.create(:price_group, :facility => @facility)
#      @pg_user_member = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
#      @order          = @user.orders.create(Factory.attributes_for(:order, :facility_id => @facility.id, :account_id => @account.id, :created_by => @user.id))
#      @instrument     = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
#      @order_detail   = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @instrument.id, :account_id => @account.id))
#    end


    context 'problem orders' do

#      before :each do
#        @rule           = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule).merge(:start_hour => 0, :end_hour => 17))
#        @instrument_pp  = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :price_group_id => @price_group.id))
#        @reservation    = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour => 10,
#                                                          :reserve_start_min => 0, :reserve_start_meridian => 'am',
#                                                          :duration_value => 60, :duration_unit => 'minutes')
#
#        @order_detail.reservation=@reservation
#        define_open_account(@order_detail.product.account, @order_detail.account.account_number)
#        Factory.create(:price_group_product, :product => @instrument, :price_group => @price_group)
#
#        PurchaseAccountTransaction.create!(
#          :order_detail => @order_detail,
#          :transaction_amount => 10,
#          :facility => @facility,
#          :account => @account,
#          :created_by => @user.id,
#          :is_in_dispute => false
#        )
#
#        @order_detail.to_inprocess!
#        @order_detail.to_complete!
#      end


      # The setup for instrument order tests is absolutely painful...
      it 'should test that an order with no actual start date is a problem'
      it 'should test that an order with no actual end date is a problem'
      it 'should test that an order with actuals is not a problem'

    end

    context "instrument purchase validation" do
      it "should validate for a valid instrument with reservation"
      it "should not be valid if an instrument reservation is not valid"
      it "should not be valid if there is no estimated or actual price"
    end

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


    it "should not transition from 'inprocess' to 'completed' if there is no purchase account transaction" do
      @order_detail.to_inprocess!
      @order_detail.to_complete!
      @order_detail.state.should == 'inprocess'
      @order_detail.version.should == 2
    end


    context 'exits with #assign_price_policy' do

      before :each do
        @price_group3 = Factory.create(:price_group, :facility => @facility)
        UserPriceGroupMember.create!(:price_group => @price_group3, :user => @user)
        Factory.create(:price_group_product, :product => @item, :price_group => @price_group3, :reservation_window => nil)

        PurchaseAccountTransaction.create!(
          :order_detail => @order_detail,
          :transaction_amount => 10,
          :facility => @facility,
          :account => @account,
          :created_by => @user.id,
          :is_in_dispute => false
        )

        @order_detail.reload
      end


      it 'should assign a price policy' do
        pp=Factory.create(:item_price_policy, :item => @item, :price_group => @price_group3)
        @order_detail.price_policy.should be_nil
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.state.should == 'complete'
        @order_detail.price_policy.should == pp
        @order_detail.should_not be_cost_estimated
        @order_detail.should_not be_problem_order

        costs=pp.calculate_cost_and_subsidy(@order_detail.quantity)
        @order_detail.actual_cost.should == costs[:cost]
        @order_detail.actual_subsidy.should == costs[:subsidy]
      end


      it 'should not assign a price policy' do
        @order_detail.price_policy.should be_nil
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.state.should == 'complete'
        @order_detail.price_policy.should be_nil
        @order_detail.should be_problem_order
      end

    end

  end
end
