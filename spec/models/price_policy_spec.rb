require "rails_helper"

RSpec.describe PricePolicy do
  before :all do
    # Settings should be 09-01 or 08-01
    Settings.financial.fiscal_year_begins = "10-01"
  end
  after :all do
    Settings.reload!
  end

  let(:facility) { @facility }

  before :each do
    @facility         = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @price_group = FactoryGirl.create(:price_group, facility: facility)
    @item             = @facility.items.create(FactoryGirl.attributes_for(:item, facility_account_id: @facility_account.id))
  end

  [:unit_cost, :unit_subsidy, :usage_rate, :usage_subsidy, :reservation_rate, :overage_rate, :overage_subsidy, :minimum_cost].each do |rate|
    it { is_expected.to validate_numericality_of(rate) }
    it { is_expected.not_to allow_value(-10).for(rate) }
  end

  it "should not create using factory" do
    # putting inside begin/rescue as some PricePolicy validation functions throw exception if type is nil
    begin
      @pp = PricePolicy.create(FactoryGirl.attributes_for(:item_price_policy, price_group_id: @price_group.id, product_id: @item.id))
      expect(@pp).not_to be_valid
      expect(@pp.errors[:type]).not_to be_nil
    rescue
      true
    end
  end

  context "expire date" do
    before :each do
      @start_date = Time.zone.parse("2020-5-5")
    end

    it "should set default expire_date" do
      @pp = FactoryGirl.create(:item_price_policy, price_group_id: @price_group.id, product_id: @item.id, start_date: @start_date, expire_date: nil)
      expect(@pp.expire_date).not_to be_nil
      expect(@pp.expire_date).to eq(Time.zone.parse("2020-9-30").end_of_day)
    end

    it "should not allow an expire date the same as start date" do
      pp = ItemPricePolicy.new(
        FactoryGirl.attributes_for(:item_price_policy,
                                   price_group_id: @price_group.id,
                                   product_id: @item.id,
                                   start_date: @start_date,
                                   expire_date: @start_date),
      )

      assert !pp.save
      assert pp.errors[:expire_date]
    end

    it "should not allow an expire date after a generated date" do
      pp = ItemPricePolicy.new(
        FactoryGirl.attributes_for(:item_price_policy,
                                   price_group_id: @price_group.id,
                                   product_id: @item.id,
                                   start_date: @start_date,
                                   expire_date: PricePolicy.generate_expire_date(@start_date) + 1.month),
      )
      assert !pp.save
      assert pp.errors[:expire_date]
    end

    it "should not set default expire_date if one is given" do
      expire_date = @start_date + 3.months
      pp = FactoryGirl.create(:item_price_policy, price_group_id: @price_group.id, product_id: @item.id, start_date: @start_date, expire_date: expire_date)
      expect(pp.expire_date).not_to be_nil
      expect(pp.expire_date).to eq(expire_date)
    end

    it "should not be expired" do
      expire_date = @start_date + 3.months
      pp = FactoryGirl.create(:item_price_policy, price_group_id: @price_group.id, product_id: @item.id, start_date: @start_date, expire_date: expire_date)
      expect(pp).not_to be_expired
    end

    it "should be expired" do
      @start_date = Time.zone.parse("2000-5-5")
      expire_date = @start_date + 1.month
      pp = FactoryGirl.create(:item_price_policy, price_group_id: @price_group.id, product_id: @item.id, start_date: @start_date, expire_date: expire_date)
      expect(pp).to be_expired
    end

  end

  context "restrict purchase" do

    before :each do
      @pp = FactoryGirl.create(:item_price_policy, product: @item, price_group: @price_group)
      # @pgp=FactoryGirl.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
    end

    it "should not restrict purchase" do
      expect(@pp.restrict_purchase).to eq(false)
    end

    it "should restrict purchase" do
      @pp.update_attributes(can_purchase: false)
      expect(@pp.restrict_purchase).to eq(true)
    end

    it "should restrict purchase" do
      @pp.restrict_purchase = true
      expect(@pp.restrict_purchase).to be true
      expect(@pp.can_purchase).to be false
    end

    it 'should alias #restrict with query method' do
      expect(@pp).to be_respond_to :restrict_purchase?
      expect(@pp.restrict_purchase).to eq(@pp.restrict_purchase?)
    end

    it "should return false when no price group present" do
      @pp.price_group = nil
      expect(@pp.restrict_purchase).to eq(false)
    end

    it "should return false when no item present" do
      @pp.product = nil
      expect(@pp.restrict_purchase).to eq(false)
    end

    it "should raise on bad input" do
      expect { @pp.restrict_purchase = 44 }.to raise_error ArgumentError
    end

    it "should destroy PriceGroupProduct when restricted" do
      @pp.restrict_purchase = true
      should_be_destroyed @pgp
    end
  end

  context "truncate old policies" do
    before :each do
      @user     = FactoryGirl.create(:user)
      @account  = FactoryGirl.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
      @price_group = FactoryGirl.create(:price_group, facility: @facility)
      @item2 = @facility.items.create(FactoryGirl.attributes_for(:item, facility_account_id: @facility_account.id))
    end
    it "should truncate the old policy" do
      @today = Time.zone.local(2011, 06, 06, 12, 0, 0)
      Timecop.freeze(@today) do
        # @today = Time.zone.local(2011, 06, 06, 12, 0, 0)

        @pp = FactoryGirl.create(:item_price_policy, product: @item, price_group: @price_group, start_date: @today.beginning_of_day, expire_date: @today + 30.days)
        @pp2 = FactoryGirl.create(:item_price_policy, product: @item, price_group: @price_group, start_date: @today + 2.days, expire_date: @today + 30.days)
        expect(@pp.reload.start_date).to eq(@today.beginning_of_day)
        expect(@pp.expire_date).to be < (@today + 1.day).end_of_day
        expect(@pp2.reload.start_date).to eq(@today + 2.days)
        expect(@pp2.expire_date).to eq(@today + 30.days)
      end
    end

    it "should not truncate any other policies" do
      @today = Time.zone.local(2011, 06, 06, 12, 0, 0)

      Timecop.freeze(@today) do
        @pp = FactoryGirl.create(:item_price_policy, product: @item, price_group: @price_group, start_date: @today.beginning_of_day, expire_date: @today + 30.days)
        @pp3 = FactoryGirl.create(:item_price_policy, product: @item2, price_group: @price_group, start_date: @today, expire_date: @today + 30.days)
        @pp2 = FactoryGirl.create(:item_price_policy, product: @item, price_group: @price_group, start_date: @today + 2.days, expire_date: @today + 30.days)
        expect(@pp.reload.start_date).to eq(@today.beginning_of_day)
        expect(@pp.expire_date).to be < (@today + 1.day).end_of_day
        expect(@pp2.reload.start_date).to eq(@today + 2.days)
        expect(@pp2.expire_date).to eq(@today + 30.days)

        expect(@pp3.reload.start_date).to eq(@today)
        expect(@pp3.expire_date).to eq(@today + 30.days)
      end
    end

    context "should define abstract methods" do

      before :each do
        @sp = PricePolicy.new
      end

      it 'should abstract #calculate_cost_and_subsidy' do
        expect(@sp).to be_respond_to(:calculate_cost_and_subsidy)
        expect { @sp.calculate_cost_and_subsidy }.to raise_error RuntimeError
      end

      it 'should abstract #estimate_cost_and_subsidy' do
        expect(@sp).to be_respond_to(:estimate_cost_and_subsidy)
        expect { @sp.estimate_cost_and_subsidy }.to raise_error RuntimeError
      end

    end

    context "order assignment" do

      before :each do
        @user     = FactoryGirl.create(:user)
        @account  = FactoryGirl.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
        @order    = @user.orders.create(FactoryGirl.attributes_for(:order, created_by: @user.id))
        @order_detail = @order.order_details.create(FactoryGirl.attributes_for(:order_detail).update(product_id: @item.id, account_id: @account.id))
        @price_group = FactoryGirl.create(:price_group, facility: @facility)
        create(:account_price_group_member, account: @account, price_group: @price_group)
        FactoryGirl.create(:price_group_product, product: @item, price_group: @price_group, reservation_window: nil)
        @pp = FactoryGirl.create(:item_price_policy, product: @item, price_group: @price_group)
      end

      it "should not be assigned" do
        expect(@pp).not_to be_assigned_to_order
      end

      it "should be assigned" do
        @order_detail.reload
        @order_detail.to_inprocess!
        @order_detail.to_complete!
        expect(@pp).to be_assigned_to_order
      end

    end

  end

end
