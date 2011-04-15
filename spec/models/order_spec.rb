require 'spec_helper'

describe Order do
  it "should create using factory" do
    @user  = Factory.create(:user)
    @order = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
    @order.should be_valid
  end

  it "should require user" do
    should validate_presence_of(:user_id)
  end

  it "should require created_by" do
    should validate_presence_of(:created_by)
  end

  it "should create in new state" do
    @user  = Factory.create(:user)
    @order = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
    @order.new?.should be true
  end


  context 'total cost' do

    before :each do
      @facility       = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @user           = Factory.create(:user)
      @account        = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order          = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id))
      @item           = @facility.items.create(Factory.attributes_for(:item, :facility_account_id => @facility_account.id))
    end

    context 'actual' do
      before :each do
        @cost=@subsidy=0

        (1..4).each do |i|
          cost, subsidy=10 * i, 5 * i
          @cost += cost
          @subsidy += subsidy
          @order.order_details.create(
            Factory.attributes_for(
              :order_detail,
              :product_id => @item.id,
              :account_id => @account.id,
              :actual_cost => cost,
              :actual_subsidy => subsidy
            )
          )
        end

        @total=@cost-@subsidy
      end

      [ :total, :subsidy, :cost ].each do |method_name|
        it "should have equal #{method_name}" do
          @order.method(method_name).call.should == instance_variable_get("@#{method_name}".to_sym)
        end
      end
    end

    context 'estimated' do
      before :each do
        @estimated_cost=@estimated_subsidy=0

        (1..4).each do |i|
          cost, subsidy=10 * i, 5 * i
          @estimated_cost += cost
          @estimated_subsidy += subsidy
          @order.order_details.create(
            Factory.attributes_for(
              :order_detail,
              :product_id => @item.id,
              :account_id => @account.id,
              :estimated_cost => cost,
              :estimated_subsidy => subsidy
            )
          )
        end

        @estimated_total=@estimated_cost-@estimated_subsidy
      end

      [ :estimated_total, :estimated_subsidy, :estimated_cost ].each do |method_name|
        it "should have equal #{method_name}" do
          @order.method(method_name).call.should == instance_variable_get("@#{method_name}".to_sym)
        end
      end
    end
  end

  context 'invalidate_order state transition' do
    ## TODO decide what tests need to go here
  end

  context 'validate_order state transition' do
    before(:each) do
      @facility     = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group  = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @order_status = Factory.create(:order_status)
      @service      = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      @service_pp   = Factory.create(:service_price_policy, :service => @service, :price_group => @price_group)
      @user         = Factory.create(:user)
      @pg_member    = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @account      = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order        = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account, :facility => @facility))
    end

    it "should not validate_order if there are no order_details" do
      @order.validate_order!.should be false
    end

    it "should not allow validate if the account type is not allowed by the facility" do
      # facility does not accept credit card accounts
      @facility.accepts_cc = false
      @facility.save
      # create credit card account and link to order
      @cc_account = Factory.create(:credit_card_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @cc_account, :facility => @facility))
      @order.order_details.create(:product_id => @service.id, :quantity => 1)
      # should not be allowed to purchase with a credit card account
      @order.validate_order!.should be false
    end

    ## TODO simplify these to prevent overlapping test coverage with order_detail_spec
    it 'should validate_extras for a valid instrument with reservation'
    it 'should validate_extras for a service with no survey'
    it 'should not validate_extras for a service with a survey and no response set'
    it 'should not validate_extras for a service with a survey and a uncompleted response set'
    it 'should validate_extras for a service with a survey and a completed response set'
    it 'should not validate_extras for a service file template upload with no template results'
    it 'should validate_extras for a service file template upload with template results'
    it 'should validate_extras for a valid item'
  end

  context 'purchase state transition' do
    before(:each) do
      @facility     = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group  = Factory.create(:price_group, :facility => @facility)
      @order_status = Factory.create(:order_status)
      @service      = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      Factory.create(:price_group_product, :product => @service, :price_group => @price_group, :reservation_window => nil)
      @service_pp   = Factory.create(:service_price_policy, :service => @service, :price_group => @price_group)
      @user         = Factory.create(:user)
      @pg_member    = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @account      = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order        = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account, :facility => @facility))
    end

    it "should not allow purchase if the state is not :validated" do
      @order.order_details.create(:product_id => @service.id, :quantity => 1)
      @order.new?.should be true
      @order.save
      lambda {@order.purchase!}.should raise_exception AASM::InvalidTransition
    end

    it "place_order should mark the order with ordered_at date, purchased status, add to facility.orders collection" do
      @order.order_details.create(:product_id => @service.id, :quantity => 1, :price_policy_id => @service_pp.id, :account_id => @account.id, :actual_cost => 10, :actual_subsidy => 5)
      define_open_account(@service.account, @account.account_number)
      @order.validate_order!.should be true
      @order.purchase!.should be true
      @order.ordered_at.should_not be_nil

      # should add account to facility orders, accounts (through order_details) collections
      @facility.orders.should == [@order]
      @facility.order_details.accounts.should == [@account]
    end

    it "should check for facility active/inactive changes before purchase" do
      @order.order_details.create(:product_id => @service.id, :quantity => 1, :price_policy_id => @service_pp.id, :account_id => @account.id, :actual_cost => 10, :actual_subsidy => 5)
      define_open_account(@service.account, @account.account_number)
      @order.validate_order!.should be true

      @facility.is_active = false
      @facility.save!
      @order.reload
      @order.invalidate!
      @order.validate_order!.should be false
    end

    it "should check for product active/inactive changes before purchase" do
      @order.order_details.create(:product_id => @service.id, :quantity => 1, :price_policy_id => @service_pp.id, :account_id => @account.id, :actual_cost => 10, :actual_subsidy => 5)
      define_open_account(@service.account, @account.account_number)
      @order.validate_order!.should be true

      @service.is_archived = true
      @service.save!
      @order.reload
      @order.invalidate!
      @order.validate_order!.should be false
    end

    it "should check for schedule rule changes before purchase" do
      @instrument    = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account => @facility_account))
      @instrument_pp = Factory.create(:instrument_price_policy, :instrument => @instrument, :price_group => @price_group)
      Factory.create(:price_group_product, :product => @instrument, :price_group => @price_group)
      # default rule, 9am - 5pm all days
      @rule          = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      @order_detail  = @order.order_details.create(:product_id      => @instrument.id,    :quantity => 1,
                                                   :price_policy_id => @instrument_pp.id, :account_id => @account.id,
                                                   :estimated_cost  => 10,                :estimated_subsidy => 5)
      define_open_account(@instrument.account, @account.account_number)
      @reservation   = @instrument.reservations.create(:reserve_start_date => Date.today+1.day, :reserve_start_hour     => 9,
                                                       :reserve_start_min  => 00,               :reserve_start_meridian => 'am',
                                                       :duration_value     => 60,               :duration_unit          => 'minutes',
                                                       :order_detail       => @order_detail)
      @order.validate_order!.should be true

      @rule.start_hour = 10
      @rule.save
      @order.reload
      @order.invalidate!
      @order.validate_order!.should be false
    end

    it "should check for reservation conflicts before purchase"
    it "should check for price policy changes before purchase"
    it "should check for payment source expiration before purchase"
    it "should check for chart string account being open before purchase"
  end

  context 'add, clear, adjust' do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = Factory.create(:price_group, :facility => @facility)
      @order_status     = Factory.create(:order_status)
      @service          = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      @service_pp       = Factory.create(:service_price_policy, :service => @service, :price_group => @price_group)
      @service_same     = @facility.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account.id))
      @service_same_pp  = Factory.create(:service_price_policy, :service => @service_same, :price_group => @price_group)

      @facility2         = Factory.create(:facility)
      @facility_account2 = @facility2.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group2      = Factory.create(:price_group, :facility => @facility2)
      @service2          = @facility2.services.create(Factory.attributes_for(:service, :initial_order_status_id => @order_status.id, :facility_account_id => @facility_account2.id))
      @service2_pp       = Factory.create(:service_price_policy, :service => @service2, :price_group => @price_group2)

      @user            = Factory.create(:user)
      @pg_member       = Factory.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @account         = Factory.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @cart            = @user.orders.create(Factory.attributes_for(:order, :created_by => @user.id, :account => @account))
    end

    context 'add' do
      it "should have a facility after adding a product to the cart" do
        @cart.add(@service, 1)
        @cart.reload.facility.should == @facility
        @cart.order_details.size.should == 1
      end

      it "should throw exception for order_detail from a facility different than the cart" do
        @cart.add(@service, 1)
        @cart.order_details.size.should == 1
        lambda { @cart.add(@service2, 1) }.should raise_exception NUCore::MixedFacilityCart
        @cart.order_details.size.should == 1
      end
    end

    context 'clear' do
      it "clear should destroy all order_details and set the cart.facility to nil when clearing cart" do
        @cart.add(@service, 1)
        @cart.reload.facility.should == @facility
        @cart.clear!
        @cart.facility.should be_nil
        @cart.order_details.size.should == 0
        @cart.account.should be_nil
        @cart.state.should == 'new'
      end
    end

    context 'quantity adjustments' do
      it "should adjust the quantity" do
        @cart.add(@service, 1)
        @order_detail = @cart.reload.order_details.first
        @cart.update_quantities({@order_detail.id => 2})
        @order_detail = @cart.reload.order_details.first
        @order_detail.quantity.should == 2
      end

      it "should delete the order_detail when setting the quantity to 0" do
        @cart.add(@service, 1)
        @order_detail = @cart.order_details[0]
        @cart.update_quantities({@order_detail.id => 0})
        @cart.reload.order_details.size.should == 0
      end

      it "should clear the facility and the account when destroying the last order_detail from the cart" do
        pending
#        @cart.add(@service, 1)
#        @cart.add(@service_same, 1)
#        @cart.order_details[1].destroy
#        @cart.facility.should_not be_nil
#        @cart.account.should_not be_nil
#
#        @cart.order_details[0].destroy
#        @cart.facility.should be_nil
#        @cart.account.should be_nil
      end
    end
  end
end
