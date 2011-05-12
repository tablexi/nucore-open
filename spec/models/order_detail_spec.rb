require 'spec_helper'

describe OrderDetail do

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
      @account        = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @price_group    = Factory.create(:price_group, :facility => @facility)
      @pg_user_member = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @item_pp        = @item.item_price_policies.create(Factory.attributes_for(:item_price_policy, :price_group_id => @price_group.id))
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


    context 'needs price policy' do

      before :each do
        @price_group3 = Factory.create(:price_group, :facility => @facility)
        UserPriceGroupMember.create!(:price_group => @price_group3, :user => @user)
        Factory.create(:price_group_product, :product => @item, :price_group => @price_group3, :reservation_window => nil)
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
        @order_detail.fulfilled_at.should_not be_nil

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


      it "should transition to reconciled" do
        Factory.create(:item_price_policy, :item => @item, :price_group => @price_group3)
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 3
        @order_detail.to_reconciled!
        @order_detail.state.should == 'reconciled'
        @order_detail.version.should == 4
      end


      it "should not transition to reconciled if there are no actual costs" do
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 3
        @order_detail.to_reconciled!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 3
      end

    end

  end


  context 'statement' do
    before :each do
      @statement=Factory.create(:statement, :facility => @facility, :created_by => @user.id, :account => @account)
    end

    it { should allow_value(nil).for(:statement) }
    it { should allow_value(@statement).for(:statement) }
  end


  context 'journal' do
    before :each do
      @journal=Factory.create(:journal, :facility => @facility, :reference => 'xyz', :created_by => @user.id, :journal_date => Time.zone.now)
    end

    it { should allow_value(nil).for(:journal) }
    it { should allow_value(@journal).for(:journal) }
  end


  context 'date attributes' do
    [ :fulfilled_at, :reviewed_at ].each do |attr|
      it { should allow_value(nil).for(attr) }
      it { should allow_value(Time.zone.now).for(attr) }
    end
  end


  it "should include ids in description" do
    desc=@order_detail.to_s
    desc.should match(/#{@order_detail.id}/)
    desc.should match(/#{@order_detail.order.id}/)
  end


  context 'is_in_dispute?' do

    it 'should be in dispute' do
      @order_detail.dispute_at=Time.zone.now
      @order_detail.dispute_resolved_at=nil
      @order_detail.should be_in_dispute
    end


    it 'should not be in dispute if dispute_at is nil' do
      @order_detail.dispute_at=nil
      @order_detail.dispute_resolved_at="all good"
      @order_detail.should_not be_in_dispute
    end


    it 'should not be in dispute if dispute_resolved_at is not nil' do
      @order_detail.dispute_at=Time.zone.now
      @order_detail.dispute_resolved_at=Time.zone.now+1.day
      @order_detail.should_not be_in_dispute
    end


    it 'should not be in dispute if order detail is cancelled' do
      @order_detail.to_cancelled!
      @order_detail.dispute_at=Time.zone.now
      @order_detail.dispute_resolved_at=nil
      @order_detail.should_not be_in_dispute
    end

  end


  context 'named scopes' do

    before :each do
      @order.facility=@facility
      assert @order.save

      # extra facility records to make sure we scope properly
      @facility2 = Factory.create(:facility)
      @facility_account2 = @facility2.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user2     = Factory.create(:user)
      @item2     = @facility2.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account2.id))
      @account2  = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user2, :created_by => @user2, :user_role => 'Owner']])
      @order2    = @user2.orders.create(Factory.attributes_for(:order, :created_by => @user2.id, :facility => @facility2))
      @order_detail2 = @order2.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item2.id, :account_id => @account2.id))
    end

    it 'should give recent order details of given facility only' do
      ods=OrderDetail.facility_recent(@facility)
      ods.size.should == 1
      ods.first.should == @order_detail
    end

    it 'should give all order details for a facility' do
      ods=OrderDetail.for_facility(@facility)
      ods.size.should == 1
      ods.first.should == @order_detail
    end

    context 'unreconciled' do

      before :each do
        @account3 = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user2, :created_by => @user2, :user_role => 'Owner']])
        @order3   = @user2.orders.create(Factory.attributes_for(:order, :created_by => @user2.id, :facility => @facility2))
        @order_detail3 = @order3.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item2.id, :account_id => @account3.id))
        @order_detail2.to_complete!
        @order_detail3.to_complete!
      end

      it 'should have two unreconciled orders' do
        ods=OrderDetail.unreconciled(@facility2)
        ods.size.should == 2
        ods.should be_include @order_detail2
        ods.should be_include @order_detail3
      end

      it 'should have one unreconciled order' do
        ods=OrderDetail.account_unreconciled(@facility2, @account3)
        ods.size.should == 1
        ods[0].should == @order_detail3
      end

    end

    context 'needs statement' do

      before :each do
        @statement = Statement.create({:facility => @facility, :created_by => 1, :account => @account})
        @order_detail.update_attributes(:statement => @statement, :reviewed_at => (Time.zone.now-1.day))
        @statement2 = Statement.create({:facility => @facility2, :created_by => 1, :account => @account})
        @order_detail2.statement=@statement2
        assert @order_detail2.save
      end

      it 'should give all order details with statements for a facility' do
        ods=OrderDetail.statemented(@facility)
        ods.size.should == 1
        ods.first.should == @order_detail
      end

      it 'should give finalized order details of given facility only' do
        ods=OrderDetail.finalized(@facility)
        ods.size.should == 1
        ods.first.should == @order_detail
      end

    end

  end

end
