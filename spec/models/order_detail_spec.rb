require 'spec_helper'
require 'timecop'

describe OrderDetail do
  before(:each) do
    Settings.order_details.status_change_hooks = nil
    @facility = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @user     = Factory.create(:user)
    @item     = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    @item.should be_valid
    @account  = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
    @order    = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account, :facility => @facility))
    @order.should be_valid
    @order_detail = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
    @order_detail.state.should == 'new'
    @order_detail.version.should == 1
    @order_detail.order_status.should be_nil
  end

  context 'bundle' do

    before :each do
      @bundle=Factory.create(:bundle, :facility_account => @facility_account, :facility => @facility)
      @bundle_product=BundleProduct.create!(:bundle => @bundle, :product => @item, :quantity => 1)
      @order_detail.bundle=@bundle
      assert @order_detail.save
    end

    it 'should be bundled' do
      @order_detail.should be_bundled
    end

    it 'should not be bundled' do
      @order_detail.bundle=nil
      assert @order_detail.save
      @order_detail.should_not be_bundled
    end

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
      @pp=Factory.create(:item_price_policy, :product => @item, :price_group => @price_group)
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

  context "assigning estimated costs" do
    
    context "for reservations" do
      before(:each) do
        @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
        @price_group = Factory.create(:price_group, :facility => @facility)
        Factory.create(:price_group_product, :product => @instrument, :price_group => @price_group)
        UserPriceGroupMember.create!(:price_group => @price_group, :user => @user)
        @pp=Factory.create(:instrument_price_policy, :product=> @instrument, :price_group => @price_group)
        @rule = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule).merge(:start_hour => 0, :end_hour => 24, :duration_mins => 15))
        @order_detail.reservation = Factory.create(:reservation,
                :reserve_start_at => Time.now,
                :reserve_end_at => Time.now+1.hour,
                :instrument=> @instrument
              )
        @order_detail.product = @instrument
        @order_detail.save
        assert @order_detail.reservation
        @start_stop = [Time.now, Time.now+1.hour]
      end
      
      it "should assign_estimated_price" do
        @order_detail.estimated_cost.should be_nil
        # will be the cheapest price policy
        @order_detail.assign_estimated_price
        @order_detail.estimated_cost.should == @pp.estimate_cost_and_subsidy(*@start_stop)[:cost]
      end

      it "should assign_estimated_price_from_policy" do
        @order_detail.estimated_cost.should be_nil
        @order_detail.assign_estimated_price_from_policy(@pp)
        @order_detail.estimated_cost.should == @pp.estimate_cost_and_subsidy(*@start_stop)[:cost]
      end
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

    ## TODO will need to re-write to check for file uploads
    it 'should validate for a service with no file template upload' do
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

  describe "#problem_order?" do
    before :each do
      # create some instruments and schedule rules
      @actuals_instrument=Factory.create(:instrument,
        :facility_account => @facility_account,
        :facility => @facility
      )
      @both_instrument = Factory.create(:instrument,
        :facility_account => @facility_account,
        :facility => @facility
      )
      @no_actuals_instrument = Factory.create(:instrument,
        :facility_account => @facility_account,
        :facility => @facility
      )
      @instrument_wo_pp = Factory.create(:instrument,
        :facility_account => @facility_account,
        :facility => @facility
      )
      
      [@no_actuals_instrument, @actuals_instrument, @both_instrument, @instrument_wo_pp].each do |instrument|
        sr = Factory.create(:schedule_rule, :instrument => instrument)
      end

      # refresh associations so the instruments will know about their shiny new schedule rules
      [@no_actuals_instrument, @actuals_instrument, @both_instrument, @instrument_wo_pp].each do |instrument|
        instrument.reload
      end

      # create the price policies
      @no_actuals_instrument.instrument_price_policies.create!(Factory.attributes_for(:instrument_price_policy,
        :price_group  => @user.price_groups.first
      ))
      @actuals_instrument.instrument_price_policies.create!(Factory.attributes_for(:instrument_price_policy,
        :price_group      => @user.price_groups.first,
        :usage_rate       => 1,
        :reservation_rate => nil
      ))
      @both_instrument.instrument_price_policies.create!(Factory.attributes_for(:instrument_price_policy,
        :price_group      => @user.price_groups.first,
        :usage_rate       => 1
      ))

      # create an order and some order details 
      @order=Factory.create(:order,
        :facility => @facility,
        :user => @user,
        :created_by => @user.id,
        :account => @account,
        :ordered_at => Time.zone.now
      )

      # create the order_details
      @no_actuals_od  = Factory.create(:order_detail, :order => @order, :product => @no_actuals_instrument)
      @actuals_od     = Factory.create(:order_detail, :order => @order, :product => @actuals_instrument)
      @both_od        = Factory.create(:order_detail, :order => @order, :product => @both_instrument)
      @no_pp_od       = Factory.create(:order_detail, :order => @order, :product => @instrument_wo_pp)


      @no_actuals_od.reservation = Factory(:reservation, :instrument => @no_actuals_instrument)
      @no_actuals_od.save!
      @actuals_od.reservation = Factory(:reservation, :instrument => @actuals_instrument)
      @actuals_od.save!
      @both_od.reservation = Factory(:reservation, :instrument => @both_instrument)
      @both_od.save!
      @no_pp_od.reservation = Factory(:reservation, :instrument => @both_instrument)
      @no_pp_od.save!
      
      # travel to the future to complete the order_details
      Timecop.travel(2.days.from_now) do
        [@no_actuals_od, @actuals_od, @both_od, @no_pp_od].each do |od|
          od.change_status!(OrderStatus.find_by_name('In Process'))
          od.state.should == 'inprocess'
          od.change_status!(OrderStatus.find_by_name('Complete'))
          od.state.should == 'complete'
        end
      end

      [@no_actuals_od, @actuals_od, @both_od, @no_pp_od].each do |od|
        od.reload
      end

    end

    context "run on an order_detail for an instrument who's price policy" do
      context "does not require actuals" do
        it "should complete" do
          @no_actuals_od.state.should == 'complete'
        end

        it "should not be a problem order" do
          @no_actuals_od.problem_order?.should be_false
        end
      end

      context "requires actuals" do
        it "should complete" do
          @actuals_od.state.should == 'complete'
        end

        it "should be a problem order" do
          @actuals_od.problem_order?.should be_true
        end
      end

      context "requires actuals and has a reservation_rate" do
        it "should complete" do
          @both_od.state.should == 'complete'
        end

        it "should be a problem order" do
          @both_od.problem_order?.should be_true
        end
      end

      context "doesn't exist" do
        it "should complete" do
          @no_pp_od.state.should == 'complete'
        end

        it "should be a problem order" do
          @no_pp_od.problem_order?.should be_true
        end
      end
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
        pp=Factory.create(:item_price_policy, :product => @item, :price_group => @price_group3)
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

      it "should transition to cancelled" do
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.to_cancelled!
        @order_detail.state.should == 'cancelled'
        @order_detail.version.should == 4
      end

      it "should not transition to cancelled from reconciled" do
        Factory.create(:item_price_policy, :product => @item, :price_group => @price_group3)
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.to_reconciled!
        lambda { @order_detail.to_cancelled! }.should raise_exception AASM::InvalidTransition
        @order_detail.state.should == 'reconciled'
        @order_detail.version.should == 4
      end

      it "should not transition to cancelled if part of journal" do
        journal=Factory.create(:journal, :facility => @facility, :reference => 'xyz', :created_by => @user.id, :journal_date => Time.zone.now)
        @order_detail.update_attribute :journal_id, journal.id
        @order_detail.reload.journal.should == journal
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.to_cancelled!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 4
      end

      it "should not transition to cancelled if part of statement" do
        statement=Factory.create(:statement, :facility => @facility, :created_by => @user.id, :account => @account)
        @order_detail.update_attribute :statement_id, statement.id
        @order_detail.reload.statement.should == statement
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        @order_detail.to_cancelled!
        @order_detail.state.should == 'complete'
        @order_detail.version.should == 4
      end

      it "should transition to reconciled" do
        Factory.create(:item_price_policy, :product => @item, :price_group => @price_group3)
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
  
  context "can_dispute?" do
    before :each do
      @order_detail.to_complete
      @order_detail.reviewed_at = 1.day.from_now
      @order_detail.save
      
      @order_detail2 = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
      @order_detail2.to_complete
      @order_detail2.reviewed_at = 1.day.ago
      @order_detail2.save!
    end
    
    it 'should not be disputable if its not complete' do
      @order_detail3 = @order.order_details.create(Factory.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
      @order_detail3.should_not be_can_dispute
    end
    it 'should not be in dispute if the review date has passed' do
      @order_detail.should be_can_dispute
      @order_detail2.should_not be_can_dispute
    end
    
    it "should not be in dispute if it's already been disputed" do
      @order_detail.dispute_at = 1.hour.ago
      @order_detail.dispute_reason = "because"
      @order_detail.save!
      @order_detail.should_not be_can_dispute
    end
  end

  context 'review period' do
    after :each do
      Settings.reload!
    end
    context '7 day' do
      before :each do
        Settings.billing.review_period = 7.days
      end
      it 'should not have a reviewed time' do
        @order_detail.to_complete
        @order_detail.reviewed_at.should be_nil
      end
    end
    context 'zero day' do
      before :each do
        Settings.billing.review_period = 0.days
      end
      it 'should set reviewed_at to now' do
        @order_detail.to_complete
        @order_detail.reviewed_at.should < Time.zone.now
      end
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


    context 'reservations' do
      before :each do
        @now=Time.zone.now
        setup_reservation @facility, @facility_account, @account, @user
      end


      it 'should be upcoming' do
        start_time=@now+2.days
        place_reservation @facility, @order_detail, start_time, { :reserve_end_at => start_time+1.hour }
        upcoming=OrderDetail.upcoming_reservations.all
        upcoming.size.should == 1
        upcoming[0].should == @order_detail
      end


      it 'should not be upcoming because reserve_end_at is in the past' do
        start_time=@now-2.days
        place_reservation @facility, @order_detail, start_time, { :reserve_end_at => start_time+1.hour }
        OrderDetail.upcoming_reservations.all.should be_blank
      end


      it 'should not be upcoming because actual_start_at exists' do
        start_time=@now+2.days
        place_reservation @facility, @order_detail, start_time, { :reserve_end_at => start_time+1.hour, :actual_start_at => start_time }
        OrderDetail.upcoming_reservations.all.should be_blank
      end


      it 'should be in progress' do
        place_reservation @facility, @order_detail, @now, { :actual_start_at => @now }
        upcoming=OrderDetail.in_progress_reservations.all
        upcoming.size.should == 1
        upcoming[0].should == @order_detail
      end


      it 'should not be in progress because actual_start_at missing' do
        place_reservation @facility, @order_detail, @now
        OrderDetail.in_progress_reservations.all.should be_empty
      end


      it 'should not be in progress because actual_end_at exists' do
        start_time=@now-3.hour
        place_reservation @facility, @order_detail, start_time, { :actual_start_at => start_time, :actual_end_at => start_time+1.hour }
        OrderDetail.in_progress_reservations.all.should be_empty
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

  context 'ordered_on_behalf_of?' do
    it 'should return true if the associated order was ordered by someone else' do
      @user2 = Factory.create(:user)
      @order_detail.order.update_attributes(:created_by_user => @user2)
      @order_detail.reload.should be_ordered_on_behalf_of
    end
    it 'should return false if the associated order was not ordered on behalf of' do
      user = @order_detail.order.user
      @order_detail.order.update_attributes(:created_by_user => user)
      @order_detail.reload
      @order_detail.reload.should_not be_ordered_on_behalf_of
    end
  end
  
  context 'ordered_or_reserved_in_range' do
    before :each do
      @user = Factory.create(:user)
      @od_yesterday = place_product_order(@user, @facility, @item, @account)
      @od_yesterday.order.update_attributes(:ordered_at => (Time.zone.now - 1.day))
      
      @od_tomorrow = place_product_order(@user, @facility, @item, @account)
      @od_tomorrow.order.update_attributes(:ordered_at => (Time.zone.now + 1.day))
      
      @od_today = place_product_order(@user, @facility, @item, @account)

      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument=@facility.instruments.create(
          Factory.attributes_for(
            :instrument,
            :facility_account => @facility_account,
            :min_reserve_mins => 60,
            :max_reserve_mins => 60
          )
      )
      # all reservations get placed in today
      @reservation_yesterday = place_reservation_for_instrument(@user, @instrument, @account, Time.zone.now - 1.day)
      @reservation_tomorrow = place_reservation_for_instrument(@user, @instrument, @account, Time.zone.now + 1.day)      
      @reservation_today = place_reservation_for_instrument(@user, @instrument, @account, Time.zone.now)
    end

    it "should only return the reservations and the orders from today and tomorrow" do
      result = OrderDetail.ordered_or_reserved_in_range(Time.zone.now, nil)
      result.should contain_all [@od_today, @od_tomorrow, @reservation_today.order_detail, @reservation_tomorrow.order_detail]
    end
    
    it "should only return the reservations and the orders from today and yesterday" do
      result = OrderDetail.ordered_or_reserved_in_range(nil, Time.zone.now)
      result.should contain_all [@od_yesterday, @od_today, @reservation_yesterday.order_detail, @reservation_today.order_detail]
    end

    it "should only return the order detail and the reservation from today" do
      result = OrderDetail.ordered_or_reserved_in_range(Time.zone.now, Time.zone.now)
      result.should contain_all [@od_today, @reservation_today.order_detail]
    end
  end

  context 'cancel_reservation' do
    before :each do
      start_date=Time.zone.now+1.day
      setup_reservation @facility, @facility_account, @account, @user
      place_reservation @facility, @order_detail, start_date
      InstrumentPricePolicy.all.each{|pp| pp.update_attribute :cancellation_cost, 5.0}
      Factory.create :user_price_group_member, :user_id => @user.id, :price_group_id => @price_group.id
    end

    it 'should cancel as admin and not have cancellation fee' do
      @order_detail.cancel_reservation(@user, OrderStatus.cancelled.first, true).should be_true
      @reservation.reload.canceled_by.should == @user.id
      @reservation.canceled_at.should_not be_nil
      @order_detail.reload.state.should == 'cancelled'
    end

    it 'should not cancel as user if reservation was already cancelled' do
      @instrument.update_attribute :min_cancel_hours, 25
      @reservation.update_attribute :canceled_at, Time.zone.now
      @order_detail.cancel_reservation(@user).should be_false
    end

    it 'should cancel as admin and add cancellation fee' do
      cancel_with_fee @user, OrderStatus.cancelled.first, true, true
    end

    it 'should cancel as user and add cancellation fee' do
      cancel_with_fee @user
    end

    def cancel_with_fee(*cancel_reservation_args)
      @instrument.update_attribute :min_cancel_hours, 25
      # make sure the @order_detail's product is up to date with the new min_cancel_hours
      @order_detail.reload
      @order_detail.cancel_reservation(*cancel_reservation_args).should be_true
      @reservation.reload.canceled_by.should == @user.id
      @reservation.canceled_at.should_not be_nil
      @order_detail.reload.state.should == 'complete'
      @order_detail.actual_cost.should == @order_detail.price_policy.cancellation_cost
      @order_detail.actual_subsidy.should == 0
    end
    
  end

end
