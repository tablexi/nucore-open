require 'spec_helper'

describe ServicePricePolicy do
  it "should create a price policy for tomorrow if no policies already exist for that day" do
    should allow_value(Date.today+1).for(:start_date)
  end

  it "should create a price policy for yesterday" do
    should allow_value(Date.today - 1).for(:start_date)
  end

  it "should return cost - subsidy as the total" do
    ipp = ServicePricePolicy.new(:unit_cost => 10.75, :unit_subsidy => 0)
    ipp.unit_total.to_f.should == 10.75
    ipp = ServicePricePolicy.new(:unit_cost => 10.75, :unit_subsidy => 0.75)
    ipp.unit_total.to_f.should == 10
  end

  context 'validations' do
    it { should validate_numericality_of :unit_cost }
    it 'should not allow a subsidy more than cost' do
      pp = FactoryGirl.build(:item_price_policy, :unit_subsidy => 10, :unit_cost => 5)
      pp.should_not be_valid
      pp.errors.keys.should be_include :unit_subsidy
    end
  end

  context "test requiring services" do
    before(:each) do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
      @service             = @facility.services.create(FactoryGirl.attributes_for(:service, :facility_account => @facility_account))
      @price_group_product=FactoryGirl.create(:price_group_product, :product => @service, :price_group => @price_group, :reservation_window => nil)
    end

    it "should create using factory" do
      # price policy belongs to an service and a price group
      ipp = @service.service_price_policies.create(FactoryGirl.attributes_for(:service_price_policy, :price_group => @price_group))
      ipp.should be_valid
    end

    it 'should return the item' do
      ipp = @service.service_price_policies.create(FactoryGirl.attributes_for(:service_price_policy, :start_date => Date.today, :price_group_id => @price_group.id))
      ipp.product.should == @service
    end

    it "should create a price policy for today if no active price policy already exists" do
      should allow_value(Date.today).for(:start_date)
      ipp     = @service.service_price_policies.create(:unit_cost => 1, :unit_subsidy => 0, :start_date => Date.today - 7,
                                                 :price_group => @price_group)
      ipp.save(:validate => false)
      ipp_new = @service.service_price_policies.create(:unit_cost => 1, :unit_subsidy => 0, :start_date => Date.today,
                                                 :price_group => @price_group)
      ipp_new.errors_on(:start_date).should_not be_nil
    end

    it "should not create a price policy for a day that a policy already exists for" do
      ipp     = @service.service_price_policies.create(FactoryGirl.attributes_for(:service_price_policy, :start_date => Date.today + 7, :price_group_id => @price_group.id))
      ipp_new = @service.service_price_policies.create(FactoryGirl.attributes_for(:service_price_policy, :start_date => Date.today + 7, :price_group_id => @price_group.id))
      ipp_new.errors_on(:start_date).should_not be_nil
    end

    it "should calculate the cost for an 1 service" do
      ipp   = @service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today, :price_group_id => @price_group.id, :can_purchase => true)
      costs = ipp.calculate_cost_and_subsidy
      costs[:cost].to_f.should == 10.75
      costs[:subsidy].to_f.should == 0.75
    end

    it "should calculate the cost for multiple service when given a quantity" do
      ipp   = @service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today, :price_group_id => @price_group.id, :can_purchase => true)
      costs = ipp.calculate_cost_and_subsidy(2)
      costs[:cost].to_f.should == 21.5
      costs[:subsidy].to_f.should == 1.5
    end

    it 'should estimate the same as calculate' do
      ipp   = @service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today, :price_group_id => @price_group.id)
      ipp.estimate_cost_and_subsidy(2).should == ipp.calculate_cost_and_subsidy(2)
    end

    it "should return a cost of nil if the purchase is restricted" do
      @price_group_product.destroy
      ipp = @service.service_price_policies.create(:start_date => Date.today, :price_group_id => @price_group.id)
      ipp.calculate_cost_and_subsidy.should be_nil
    end

    it "should return the date for the current policies" do
      spp = @service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today - 7.days, :price_group_id => @price_group.id)
      @service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today + 7.days, :price_group_id => @price_group.id)
      ServicePricePolicy.current_date(@service).should == spp.start_date.to_date
      spp3 = @service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today, :price_group_id => @price_group.id)
      ServicePricePolicy.current_date(@service).should == spp3.start_date.to_date
    end

    it "should return the date for upcoming policies" do
      @service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today, :price_group_id => @price_group.id)
      spp2=@service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today + 7.days, :price_group_id => @price_group.id)
      spp3=@service.service_price_policies.create(:unit_cost => 10.75, :unit_subsidy => 0.75, :start_date => Date.today + 14.days, :price_group_id => @price_group.id)

      ServicePricePolicy.next_date(@service).should == spp2.start_date.to_date
      next_dates = ServicePricePolicy.next_dates(@service)
      next_dates.length.should == 2
      next_dates.include?(spp2.start_date.to_date).should be_true
      next_dates.include?(spp3.start_date.to_date).should be_true
    end
  end
end
