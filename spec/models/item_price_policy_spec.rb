require "rails_helper"

RSpec.describe ItemPricePolicy do
  it "should create a price policy for tomorrow if no policies already exist for that day" do
    is_expected.to allow_value(Date.today+1).for(:start_date)
  end

  it "should create a price policy for yesterday" do
    is_expected.to allow_value(Date.today - 1).for(:start_date)
  end

  it "should return cost - subsidy as the total" do
    ipp = ItemPricePolicy.new(:unit_cost => 10.75, :unit_subsidy => 0)
    expect(ipp.unit_total.to_f).to eq(10.75)
    ipp = ItemPricePolicy.new(:unit_cost => 10.75, :unit_subsidy => 0.75)
    expect(ipp.unit_total.to_f).to eq(10)
  end

  context 'validations' do
    it { is_expected.to validate_numericality_of :unit_cost }
    it 'should not allow a subsidy more than cost' do
      pp = FactoryGirl.build(:item_price_policy, :unit_subsidy => 10, :unit_cost => 5)
      expect(pp).not_to be_valid
      expect(pp.errors.keys).to be_include :unit_subsidy
    end
  end
  context "test requiring items" do
    before(:each) do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
      @item             = @facility.items.create(FactoryGirl.attributes_for(:item, :facility_account => @facility_account))
      @price_group_product=FactoryGirl.create(:price_group_product, :product => @item, :price_group => @price_group, :reservation_window => nil)
    end

    it "should create using factory" do
      # price policy belongs to an item and a price group
      ipp = @item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :price_group => @price_group))
      expect(ipp).to be_valid
    end

    it 'should return the item' do
      ipp = @item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :start_date => Date.today, :price_group_id => @price_group.id))
      expect(ipp.product).to eq(@item)
    end

    it "should create a price policy for today if no active price policy already exists" do
      is_expected.to allow_value(Date.today).for(:start_date)
      ipp     = @item.item_price_policies.create(:unit_cost => 1, :unit_subsidy => 0, :start_date => Date.today - 7,
                                                 :price_group => @price_group)
      ipp.save(:validate => false)
      ipp_new = @item.item_price_policies.create(:unit_cost => 1, :unit_subsidy => 0, :start_date => Date.today,
                                                 :price_group => @price_group)
      expect(ipp_new.errors_on(:start_date)).not_to be_nil
    end

    it "should not create a price policy for a day that a policy already exists for" do
      ipp_new = @item.item_price_policies.create(FactoryGirl.attributes_for(:item_price_policy, :start_date => Date.today + 7, :price_group_id => @price_group.id))
      expect(ipp_new.errors_on(:start_date)).not_to be_nil
    end

    it "should calculate the cost for an 1 item" do
      ipp   = @item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today, :price_group_id => @price_group.id, :can_purchase => true)
      costs = ipp.calculate_cost_and_subsidy
      expect(costs[:cost].to_f).to eq(10.75)
      expect(costs[:subsidy].to_f).to eq(0.75)
    end

    it "should calculate the cost for multiple item when given a quantity" do
      ipp   = @item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today, :price_group_id => @price_group.id, :can_purchase => true)
      costs = ipp.calculate_cost_and_subsidy(2)
      expect(costs[:cost].to_f).to eq(21.5)
      expect(costs[:subsidy].to_f).to eq(1.5)
    end

    it "should estimate the same as calculate" do
      ipp   = @item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today, :price_group_id => @price_group.id, :can_purchase => true)
      expect(ipp.estimate_cost_and_subsidy(2)).to eq(ipp.calculate_cost_and_subsidy(2))
    end

    it "should return a cost of nil if the purchase is restricted" do
      @price_group_product.destroy
      ipp = @item.item_price_policies.create(:start_date => Date.today, :price_group_id => @price_group.id)
      expect(ipp.calculate_cost_and_subsidy).to be_nil
    end

    it "should return the date for the current policies" do
      ipp = @item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today - 7.days, :price_group_id => @price_group.id, :can_purchase => true)
      @item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today + 7.days, :price_group_id => @price_group.id)
      expect(ItemPricePolicy.current_date(@item).to_date).to eq(ipp.start_date.to_date)
      ipp3 = @item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today, :price_group_id => @price_group.id)
      expect(ItemPricePolicy.current_date(@item).to_date).to eq(ipp3.start_date.to_date)
    end

    it "should return the date for upcoming policies" do
      @item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today, :price_group_id => @price_group.id, :can_purchase => true)
      ipp2=@item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today + 7.days, :price_group_id => @price_group.id, :can_purchase => true)
      ipp3=@item.item_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75,  :start_date => Date.today + 14.days, :price_group_id => @price_group.id, :can_purchase => true)

      expect(ItemPricePolicy.next_date(@item).to_date).to eq(ipp2.start_date.to_date)
      next_dates = ItemPricePolicy.next_dates(@item)
      expect(next_dates.length).to eq(2)
      expect(next_dates.include?(ipp2.start_date.to_date)).to be true
      expect(next_dates.include?(ipp3.start_date.to_date)).to be true
    end
  end
end
