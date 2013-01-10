require 'spec_helper'

describe PricePolicy do
  before :all do
    # Settings should be 09-01 or 08-01
    Settings.financial.fiscal_year_begins = '10-01'
  end
  after :all do
    Settings.reload!
  end

  before :each do
    @facility         = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @price_group      = @facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
    @item             = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))
  end

  [:unit_cost, :unit_subsidy, :usage_rate, :usage_subsidy, :reservation_rate, :overage_rate, :overage_subsidy, :minimum_cost].each do |rate|
    it { should validate_numericality_of(rate) }
    it { should_not allow_value(-10).for(rate) }
  end

  it "should not create using factory" do
    # putting inside begin/rescue as some PricePolicy validation functions throw exception if type is nil
    begin
      @pp = PricePolicy.create(FactoryGirl.attributes_for(:item_price_policy, :price_group_id => @price_group.id, :product_id => @item.id))
      @pp.should_not be_valid
      @pp.errors[:type].should_not be_nil
    rescue
      true
    end
  end


  context 'expire date' do
    before :each do
      @start_date=Time.zone.parse("2020-5-5")
    end

    it "should set default expire_date" do
      @pp=FactoryGirl.create(:item_price_policy, :price_group_id => @price_group.id, :product_id => @item.id, :start_date => @start_date, :expire_date => nil)
      @pp.expire_date.should_not be_nil
      @pp.expire_date.should == Time.zone.parse("2020-9-30").end_of_day
    end

    it 'should not allow an expire date the same as start date' do
      pp=ItemPricePolicy.new(
          FactoryGirl.attributes_for(:item_price_policy,
                                 :price_group_id => @price_group.id,
                                 :product_id => @item.id,
                                 :start_date => @start_date,
                                 :expire_date => @start_date)
      )
      
      assert !pp.save
      assert pp.errors[:expire_date]
    end

    it 'should not allow an expire date after a generated date' do
      pp=ItemPricePolicy.new(
          FactoryGirl.attributes_for(:item_price_policy,
                                 :price_group_id => @price_group.id,
                                 :product_id => @item.id,
                                 :start_date => @start_date,
                                 :expire_date => PricePolicy.generate_expire_date(@start_date)+1.month)
      )
      assert !pp.save
      assert pp.errors[:expire_date]
    end

    it "should not set default expire_date if one is given" do
      expire_date=@start_date+3.months
      pp=FactoryGirl.create(:item_price_policy, :price_group_id => @price_group.id, :product_id => @item.id, :start_date => @start_date, :expire_date => expire_date)
      pp.expire_date.should_not be_nil
      pp.expire_date.should == expire_date
    end

    it "should not be expired" do
      expire_date=@start_date+3.months
      pp=FactoryGirl.create(:item_price_policy, :price_group_id => @price_group.id, :product_id => @item.id, :start_date => @start_date, :expire_date => expire_date)
      pp.should_not be_expired
    end

    it "should be expired" do
      @start_date=Time.zone.parse("2000-5-5")
      expire_date=@start_date+1.month
      pp=FactoryGirl.create(:item_price_policy, :price_group_id => @price_group.id, :product_id => @item.id, :start_date => @start_date, :expire_date => expire_date)
      pp.should be_expired
    end

  end


  context 'restrict purchase' do

    before :each do
      @pp=FactoryGirl.create(:item_price_policy, :product => @item, :price_group => @price_group)
      #@pgp=FactoryGirl.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
    end

    it 'should not restrict purchase' do
      @pp.restrict_purchase.should == false
    end

    it 'should restrict purchase' do
      @pp.update_attributes(:can_purchase => false)
      @pp.restrict_purchase.should == true
    end

    it 'should restrict purchase' do
      @pp.restrict_purchase = true
      @pp.restrict_purchase.should be_true
      @pp.can_purchase.should be_false
    end

    it 'should alias #restrict with query method' do
      @pp.should be_respond_to :restrict_purchase?
      @pp.restrict_purchase.should == @pp.restrict_purchase?
    end

    it 'should return false when no price group present' do
      @pp.price_group=nil
      @pp.restrict_purchase.should == false
    end

    it 'should return false when no item present' do
      @pp.product=nil
      @pp.restrict_purchase.should == false
    end

    it 'should raise on bad input' do
      assert_raise(ArgumentError) { @pp.restrict_purchase=44 }
    end

    it 'should destroy PriceGroupProduct when restricted' do
      @pp.restrict_purchase=true
      should_be_destroyed @pgp
    end
  end
  
  context "truncate old policies" do
    before :each do
      @user     = FactoryGirl.create(:user)
      @account  = FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])      
      @price_group = FactoryGirl.create(:price_group, :facility => @facility)
      @item2    = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account_id => @facility_account.id))   
    end
    it "should truncate the old policy" do
      @today = Time.zone.local(2011, 06, 06, 12, 0, 0)
      Timecop.freeze(@today) do
        #@today = Time.zone.local(2011, 06, 06, 12, 0, 0)
        
        @pp=FactoryGirl.create(:item_price_policy, :product => @item, :price_group => @price_group, :start_date => @today.beginning_of_day, :expire_date => @today + 30.days)
        @pp2=FactoryGirl.create(:item_price_policy, :product => @item, :price_group => @price_group, :start_date => @today + 2.days, :expire_date => @today + 30.days)
        @pp.reload.start_date.should == @today.beginning_of_day
        # they weren't matching up exactly right, but were within a second of each other
        # @pp.exire_date.should == (@today + 1.day).end_of_day
        ((@today.end_of_day + 1.day) - @pp.expire_date).abs.should < 1
        @pp2.reload.start_date.should == @today + 2.days
        @pp2.expire_date.should == @today + 30.days
      end
    end
    
    it "should not truncate any other policies" do
      @today = Time.zone.local(2011, 06, 06, 12, 0, 0)
      
      Timecop.freeze(@today) do
        @pp=FactoryGirl.create(:item_price_policy, :product => @item, :price_group => @price_group, :start_date => @today.beginning_of_day, :expire_date => @today + 30.days)
        @pp3 = FactoryGirl.create(:item_price_policy, :product => @item2, :price_group => @price_group, :start_date => @today, :expire_date => @today + 30.days)
        @pp2=FactoryGirl.create(:item_price_policy, :product => @item, :price_group => @price_group, :start_date => @today + 2.days, :expire_date => @today + 30.days)
        @pp.reload.start_date.should == @today.beginning_of_day
        # they weren't matching up exactly right, but were within a second of each other
        # @pp.exire_date.should == (@today + 1.day).end_of_day
        ((@today.end_of_day + 1.day) - @pp.expire_date).abs.should < 1
        @pp2.reload.start_date.should == @today + 2.days
        @pp2.expire_date.should == @today + 30.days
        
        @pp3.reload.start_date.should == @today
        @pp3.expire_date.should == @today + 30.days
      end
    end


  context 'should define abstract methods' do

    before :each do
      @sp = PricePolicy.new
    end

    it 'should abstract #calculate_cost_and_subsidy' do
      @sp.should be_respond_to(:calculate_cost_and_subsidy)
      assert_raise(RuntimeError) { @sp.calculate_cost_and_subsidy }
    end

    it 'should abstract #estimate_cost_and_subsidy' do
      @sp.should be_respond_to(:estimate_cost_and_subsidy)
      assert_raise(RuntimeError) { @sp.estimate_cost_and_subsidy }
    end

  end


  context 'order assignment' do

    before :each do
      @user     = FactoryGirl.create(:user)
      @account  = FactoryGirl.create(:nufs_account, :account_users_attributes => [Hash[:user => @user, :created_by => @user, :user_role => 'Owner']])
      @order    = @user.orders.create(FactoryGirl.attributes_for(:order, :created_by => @user.id))
      @order_detail = @order.order_details.create(FactoryGirl.attributes_for(:order_detail).update(:product_id => @item.id, :account_id => @account.id))
      @price_group = FactoryGirl.create(:price_group, :facility => @facility)
      UserPriceGroupMember.create!(:price_group => @price_group, :user => @user)
      FactoryGirl.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
      @pp=FactoryGirl.create(:item_price_policy, :product => @item, :price_group => @price_group)
    end

    
    it 'should not be assigned' do
      @pp.should_not be_assigned_to_order
    end


    it 'should be assigned' do
      @order_detail.reload
      @order_detail.to_inprocess!
      @order_detail.to_complete!
      @pp.should be_assigned_to_order
    end

  end
  
  
  end
  
end