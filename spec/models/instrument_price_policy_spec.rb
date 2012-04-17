require 'spec_helper'

describe InstrumentPricePolicy do
  it "should create a price policy for tomorrow if no policies already exist for that day" do
    should allow_value(Date.today+1).for(:start_date)
  end

  it "should create a price policy for yesterday" do
    should allow_value(Date.today - 1).for(:start_date)
  end
  
  context "test requiring instruments" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account => @facility_account))
      @ipp=@instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :price_group => @price_group))
    end

    it "should create using factory" do
      # price policy belongs to an instrument and a price group
      @ipp.should be_valid
    end

    it "should return instrument" do
      # price policy belongs to an instrument and a price group
      @ipp.product.should == @instrument
    end

    it 'should require usage or reservation rate, but not both' do
      @ipp.restrict_purchase=false

      @ipp.should be_valid
      @ipp.reservation_rate=nil
      @ipp.usage_rate=nil
      @ipp.should_not be_valid

      @ipp.usage_rate=1
      @ipp.should be_valid

      @ipp.usage_rate=nil
      @ipp.reservation_rate=1
      @ipp.should be_valid
    end

    it 'should override #restrict_purchase=' do
      PriceGroupProduct.find_by_price_group_id_and_product_id(@price_group.id, @instrument.id).should be_nil
      @ipp.restrict_purchase=false
      pgp=PriceGroupProduct.find_by_price_group_id_and_product_id(@price_group.id, @instrument.id)
      pgp.should_not be_nil
      pgp.reservation_window.should == PriceGroupProduct::DEFAULT_RESERVATION_WINDOW
    end

    it "should create a price policy for today if no active price policy already exists" do
      should allow_value(Date.today).for(:start_date)
      @ipp.start_date=Date.today - 7.days
      @ipp.save(:validate => false) #save without validations
      ipp_new = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :start_date => Date.today, :price_group => @price_group))
      ipp_new.errors_on(:start_date).should_not be_nil
    end

    it "should not create a price policy for a day that a policy already exists for" do
      @ipp.start_date=Date.today + 7.days
      assert @ipp.save
      ipp_new = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :start_date => Date.today + 7.days, :price_group => @price_group))
      ipp_new.errors_on(:start_date).should_not be_nil
    end

    it "should return the date for the current policies" do
      @ipp.start_date=Date.today - 7.days
      @ipp.save(:validate => false) #save without validations
      @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :start_date => Date.today + 7.days, :price_group => @price_group))
      InstrumentPricePolicy.current_date(@instrument).to_date.should == Date.today - 7.days

      @ipp = @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :price_group => @price_group))
      @ipp.save(:validate => false) #save without validations
      InstrumentPricePolicy.current_date(@instrument).to_date.should == Date.today
    end

    it "should return the date for upcoming policies" do

      for i in 0..2
        @instrument.instrument_price_policies.create(Factory.attributes_for(:instrument_price_policy, :start_date => Date.today + (i*7).days, :price_group => @price_group))
      end

      InstrumentPricePolicy.next_date(@instrument).to_date.should == Date.today + 7.days
      next_dates = InstrumentPricePolicy.next_dates(@instrument)
      next_dates.length.should == 2
      next_dates.include?(Date.today + 7.days).should be_true
      next_dates.include?(Date.today + 14.days).should be_true
    end
  end
  
  # BASED ON THE MATH FUNCTION
  # duration_minutes = (end_time - start_time) / 60
  # cost = duration_minutes
  # TODO TK: finish explaining equation
  context "cost estimate tests" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account => @facility_account))
      @price_group_product=Factory.create(:price_group_product, :price_group => @price_group, :product => @instrument)
      # create rule every day from 9 am to 5 pm, no discount, duration= 30 minutes
      @rule             = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :duration_mins => 30))
    end

    it "should correctly estimate cost with usage cost" do
      pp = @instrument.instrument_price_policies.create!(ipp_attributes)
      
      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 4
      costs[:subsidy].should == 0
      
      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3 * 4
      costs[:subsidy].should == 0
      
      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3
      costs[:subsidy].should == 0
    end

    it "should correctly estimate cost with usage cost and subsidy" do
      pp = @instrument.instrument_price_policies.create!(ipp_attributes(:usage_subsidy => 1.75))

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 4
      costs[:subsidy].should == 1.75 * 4
      
      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3 * 4
      costs[:subsidy].should == 1.75 * 3 * 4
      
      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3
      costs[:subsidy].should == 1.75 * 3
    end

    it "should correctly estimate cost with usage cost and overage cost" do
      pp = @instrument.instrument_price_policies.create!(ipp_attributes(:overage_rate => 15.50))
      
      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 4
      costs[:subsidy].should == 0
      
      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3 * 4
      costs[:subsidy].should == 0
      
      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3
      costs[:subsidy].should == 0
    end

    it "should correctly estimate cost with reservation cost" do
      options = ipp_attributes({
        :usage_rate          => 0,
        :reservation_rate    => 10.75
      })

      pp = @instrument.instrument_price_policies.create!(options)
    
      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 4
      costs[:subsidy].should == 0
    
      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3 * 4
      costs[:subsidy].should == 0
    
      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3
      costs[:subsidy].should == 0
    end

    it "should correctly estimate cost with reservation cost and subsidy" do
      options = ipp_attributes({
        :usage_rate          => 0,
        :reservation_rate    => 10.75,
        :reservation_subsidy => 1.75
      })

      pp = @instrument.instrument_price_policies.create!(options)
      
      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 4
      costs[:subsidy].should == 1.75 * 4
      
      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3 * 4
      costs[:subsidy].should == 1.75 * 3 * 4
      
      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 3
      costs[:subsidy].should == 1.75 * 3
    end

    it "should correctly estimate cost with usage and reservation cost" do
      options = ipp_attributes({
        :usage_rate          => 5,
        :reservation_rate    => 5.75
      })

      pp = @instrument.instrument_price_policies.create!(options)
    
      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == (5 + 5.75) * 4
      costs[:subsidy].should == 0
    
      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == (5 + 5.75) * 3 * 4
      costs[:subsidy].should == 0
    
      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == (5 + 5.75) * 3
      costs[:subsidy].should == 0
    end

    it "should correctly estimate cost with usage and reservation cost and subsidy" do
      options = ipp_attributes({
        :usage_rate          => 5,
        :usage_subsidy       => 0.5,
        :reservation_rate    => 5.75,
        :reservation_subsidy => 0.75
      })

      pp = @instrument.instrument_price_policies.create!(options)
    
      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == (5 + 5.75) * 4
      costs[:subsidy].should == (0.5 + 0.75) * 4
    
      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == (5 + 5.75) * 3 * 4
      costs[:subsidy].should == (0.5 + 0.75) * 3 * 4
    
      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == (5 + 5.75) * 3
      costs[:subsidy].should == (0.5 + 0.75) * 3
    end

    it "should correctly estimate cost across schedule rules" do
      # create adjacent schedule rule
      @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :start_hour => @rule.end_hour, :end_hour => @rule.end_hour + 1, :duration_mins => 30))
      pp = @instrument.instrument_price_policies.create!(ipp_attributes)
    
      # 2 hour (8 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} #{@rule.end_hour - 1}:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} #{@rule.end_hour + 1}:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 8
      costs[:subsidy].should == 0
    end

    it "should correctly estimate cost for a schedule rule with a discount" do
      # create discount schedule rule
      @discount_rule = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :start_hour => @rule.end_hour, :end_hour => @rule.end_hour + 1, :duration_mins => 30, :discount_percent => 50))
      pp = @instrument.instrument_price_policies.create!(ipp_attributes)
    
      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} #{@discount_rule.start_hour}:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} #{@discount_rule.start_hour + 1}:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 0.5 * 4
      costs[:subsidy].should == 0
    end

    it "should correctly estimate cost across schedule rules with discounts" do
      # create discount schedule rule
      @discount_rule = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule, :start_hour => @rule.end_hour, :end_hour => @rule.end_hour + 1, :duration_mins => 30, :discount_percent => 50))
      pp = @instrument.instrument_price_policies.create!(ipp_attributes)
    
      # 2 hour (8 intervals); half of the time, 50% discount
      start_dt = Time.zone.parse("#{Date.today + 1.day} #{@rule.end_hour - 1}:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} #{@rule.end_hour + 1}:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == (10.75 * 0.5 * 4) + (10.75 * 4)
      costs[:subsidy].should == 0
    end

    it "should return nil if the start date is outside of the reservation window" do
      pp = @instrument.instrument_price_policies.create!(ipp_attributes)
      assert @price_group_product.save

      start_dt = Time.zone.parse("#{Date.today + 2.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 2.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs.should be_nil
      
      start_dt = Time.zone.parse("#{Date.today + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs.should_not be_nil
    end
    
    it "should return nil if the end time is earlier than the start time" do
      pp = @instrument.instrument_price_policies.create!(ipp_attributes)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 9:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs.should be_nil
    end
    
    it "should return nil for cost if purchase is restricted" do
      options = Hash[
          :start_date          => Date.today,
          :expire_date         => Date.today+7.days,
          :price_group         => @price_group,
        ]

      @price_group_product.destroy
      pp = @instrument.instrument_price_policies.create!(options)

      start_dt = Time.zone.parse("#{Date.today + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.today + 1.day} 9:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs.should be_nil
    end
    
    # TODO finish these tests
    it "should return nil if the start or end time is outside of the schedule rules" # we should catch this before price estimatation.  should probably remove this test.
    it "should apply schedule rule discounts to rate and not subsidy only" # what about a discount making [(rate * discount) - subsidy] negative?
    it "should correctly estimate cost with minimum cost" # minimum cost is before subsidies are taken int account.  but what if the subsidy is greater than the minimum cost?
    
  end
  
  context "cost estimate tests with all day schedule rules" do
    before(:each) do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create!(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create!(Factory.attributes_for(:price_group))
      @instrument       = @facility.instruments.create!(Factory.attributes_for(:instrument, :facility_account => @facility_account))
      @price_group_product=Factory.create(:price_group_product, :price_group => @price_group, :product => @instrument)
      @rule             = @instrument.schedule_rules.create!(Factory.attributes_for(:schedule_rule, :start_hour => 0, :end_hour => 24, :duration_mins => 30))
      @pp = @instrument.instrument_price_policies.create!(ipp_attributes)
    end
  
    it "should correctly estimate cost across multiple days" do
      # 2 hour (8 intervals)
      start_dt = Time.zone.parse("#{Date.today + 1.day} 23:00")
      end_dt   = Time.zone.parse("#{Date.today + 2.day} 1:00")
      costs    = @pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 8
      costs[:subsidy].should == 0
    end
    
    it "should correctly estimate costs across time changes" do
      # 4 hours (16 intervals) accounting for 1 hour DST time change
      start_dt = Time.zone.parse("7 November 2010 1:00")
      end_dt   = Time.zone.parse("7 November 2010 4:00")
      costs    = @pp.estimate_cost_and_subsidy(start_dt, end_dt)
      costs[:cost].should    == 10.75 * 16
      costs[:subsidy].should == 0
    end
  end


  def ipp_attributes(overrides={})
    attrs={
      :start_date          => Date.today,
      :expire_date         => Date.today+7.days,
      :usage_rate          => 10.75,
      :usage_subsidy       => 0,
      :usage_mins          => 15,
      :reservation_rate    => 0,
      :reservation_subsidy => 0,
      :reservation_mins    => 15,
      :overage_rate        => 0,
      :overage_subsidy     => 0,
      :overage_mins        => 15,
      :minimum_cost        => nil,
      :cancellation_cost   => nil,
      :price_group         => @price_group,
    }

    attrs.merge(overrides)
  end
  
  #TK WTF?
  context "actual cost calculation tests" do
    before :each do
      @facility         = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(Factory.attributes_for(:price_group))
      @instrument       = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account => @facility_account))
      @ipp=@instrument.instrument_price_policies.create(ipp_attributes(
        :usage_rate => 100,
        :usage_subsidy => 100,
        :usage_mins => 15,
        :overage_rate => nil,
        :overage_subsidy => nil,
        :reservation_rate => 0
      ))
    end
    it "should correctly calculate cost with usage rate"
    it "should correctly calculate cost with usage rate and subsidy"

    it "should correctly calculate cost with usage rate and subsidy and overage using usage rate for overage rate and usage subsidy for overage subsidy" do
      @reservation = Reservation.new

      # set reservation window to usage minutes from the price policy
      @reservation.reserve_start_at = Time.zone.now
      @reservation.reserve_end_at   = @reservation.reserve_start_at + @ipp.usage_mins.minutes

      # actual usage == twice as long as the reservation window
      @reservation.actual_start_at  = @reservation.reserve_start_at
      @reservation.actual_end_at    = @reservation.actual_start_at + (@ipp.usage_mins*2).minutes
      
      @costs = @ipp.calculate_cost_and_subsidy(@reservation)

      @costs[:subsidy].should == @ipp.usage_subsidy * 2
    end
    
    it "should correctly calculate cost with reservation rate, with and without actual hours"
    it "should correctly calculate cost with reservation rate and subsidy, with and without actual hours"
    it "should correctly calculate cost with usage and reservation rate and subsidy"
    it "should correctly calculate cost with usage and overage rate"
    it "should correctly calculate cost with usage and overage rate and subsidy"
    it "should correctly calculate cost with reservation and overage rate"
    it "should correctly calculate cost with reservation and overage rate and subsidy"
    it "should return nil for calculate cost with reservation and overage rate without actual hours"
    it "should correctly calculate cost with usage, reservation, and overage rate and subsidy"
    it "should correctly calculate cost across time changes"
    it "should return nil for cost if purchase is restricted"
    it "should correctly calculate cast across multiple days"
    it "should correctly calculate cost for a schedule rule with a discount"
    it "should correctly calculate cost across schedule rules"
    it "should correctly calculate cost across schedule rules with discounts"
  end
end
