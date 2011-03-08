require 'spec_helper'

describe ScheduleRule do

  it "should create using factory" do
    @facility   = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    @rule       = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
    @rule.should be_valid
  end

  context "times" do
    it "should not be valid with start hours outside 0-24" do
      should_not allow_value(-1).for(:start_hour)
      should_not allow_value(25).for(:start_hour)
      should allow_value(0).for(:start_hour)
      should allow_value(23).for(:start_hour)
    end

    it "should not be valid with start mins outside 0-59" do
      should_not allow_value(-1).for(:end_min)
      should_not allow_value(60).for(:end_min)
      should allow_value(0).for(:end_min)
      should allow_value(59).for(:end_min)
    end

    it "should allow all day rule" do
      @facility   = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @options    = Hash[:start_hour => 0, :start_min => 0, :end_hour => 24, :end_min => 0]
      @rule       = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule).merge(@options))
      assert @rule.valid?
    end

    it "should not allow end_hour == 24 and end_min != 0" do
      @facility   = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @options    = Hash[:start_hour => 0, :start_min => 0, :end_hour => 24, :end_min => 1]
      @rule       = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule).merge(@options))
      assert @rule.invalid?
      assert_equal "End time is invalid", @rule.errors.on(:base)
    end

    it "should recognize inclusive datetimes" do
      @facility   = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @rule       = @instrument.schedule_rules.build(Factory.attributes_for(:schedule_rule))
      @rule.includes_datetime(DateTime.new(1981, 9, 15, 12, 0, 0)).should == true
    end
    
    it "should not recognize non-inclusive datetimes" do
      @facility   = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      @rule       = @instrument.schedule_rules.build(Factory.attributes_for(:schedule_rule))
      @rule.includes_datetime(DateTime.new(1981, 9, 15, 3, 0, 0)).should == false
    end
  end

  it "should not allow rule conflicts" do
    @facility   = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    # create rule every day from 9 am to 5 pm
    @rule       = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
    assert @rule.valid?

    # not allow rule from 9 am to 5 pm
    @options    = Factory.attributes_for(:schedule_rule).merge(:start_hour => 9, :end_hour => 17)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors.on(:base)
    
    # not allow rule from 9 am to 10 am
    @options    = Factory.attributes_for(:schedule_rule).merge(:end_hour => 10)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors.on(:base)

    # not allow rule from 10 am to 11 am
    @options    = Factory.attributes_for(:schedule_rule).merge(:start_hour => 10, :end_hour => 11)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors.on(:base)

    # not allow rule from 3 pm to 5 pm
    @options    = Factory.attributes_for(:schedule_rule).merge(:start_hour => 15, :end_hour => 17)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors.on(:base)

    # not allow rule from 7 am to 10 am
    @options    = Factory.attributes_for(:schedule_rule).merge(:start_hour => 7, :end_hour => 10)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors.on(:base)

    # not allow rule from 4 pm to 10 pm
    @options    = Factory.attributes_for(:schedule_rule).merge(:start_hour => 16, :end_hour => 22)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors.on(:base)

    # not allow rule from 8 am to 8 pm
    @options    = Factory.attributes_for(:schedule_rule).merge(:start_hour => 8, :end_hour => 20)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors.on(:base)
  end

  it "should allow adjacent rules" do
    @facility   = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    # create rule every day from 9 am to 5 pm
    @rule       = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
    assert @rule.valid?

    # allow rule from 7 am to 9 am
    @options    = Factory.attributes_for(:schedule_rule).merge(:start_hour => 7, :end_hour => 9)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.valid?

    # allow rule from 5 pm to 12am
    @options    = Factory.attributes_for(:schedule_rule).merge(:start_hour => 17, :end_hour => 24)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.valid?
  end

  # it "should not conflict with existing reservation" do
  #   @facility   = Factory.create(:facility)
  #   @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
  #   @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
  #   # create rule every day from 9 am to 5 pm
  #   @rule1      = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
  #   assert @rule1.valid?
  # 
  #   # start/end at the exact same time
  #   @rule2      = @instrument.schedule_rules.build(Factory.attributes_for(:schedule_rule))
  #   @rule2.should_not be_valid
  # 
  #   # start/end one hour before valid rule, but times overlap
  #   @rule2.start_hour = @rule2.start_hour - 1
  #   @rule2.end_hour   = @rule2.end_hour - 1
  #   @rule2.should_not be_valid
  # end

  it "should not be valid with an end time after the start time" do
    @facility   = Factory.create(:facility)
    @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
    @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
    # create rule every day from 9 am to 5 pm
    @rule       = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
    assert @rule.valid?
    
    @rule.start_hour = 9
    @rule.start_min = 00
    @rule.end_hour = 9
    @rule.end_min = 00
    @rule.should_not be_valid

    @rule.end_hour = 8
    @rule.end_min = 20
    @rule.should_not be_valid
  end

  context "calendar object" do
    it "should build calendar object for 9-5 rule every day" do
      @facility   = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      # create rule every day from 9 am to 5 pm
      @rule       = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      assert @rule.valid?
      
      # find past sunday, and build calendar object
      @sunday   = ScheduleRule.sunday_last
      @calendar = @rule.as_calendar_object(:start_date => :sunday_last)

      # each title should be the same
      @calendar.each do |hash|
        hash["title"].should == 'Interval: 60 minutes'
        hash["allDay"].should == false
      end

      # days should start with this past sunday and end next saturday
      @calendar.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == Time.zone.parse("#{@sunday+i.days} 9:00")
        Time.zone.parse(hash['end']).should == Time.zone.parse("#{@sunday+i.days} 17:00")
      end

      # build unavailable rules from the available rules collection
      @not_available = ScheduleRule.unavailable(@rule)
      @not_available.size.should == 14
      # should mark each rule as unavailable
      assert_equal true, @not_available.first.unavailable
      @not_calendar  = @not_available.collect{ |na| na.as_calendar_object(:start_date => :sunday_last) }.flatten

      # days should be same as above
      # even times should be 12 am to 9 am
      # odd times should be 5 pm to 12 pm
      even = (0..@not_available.size).select{ |i| i.even? }
      odd  = (0..@not_available.size).select{ |i| i.odd? }

      even.collect{ |i| @not_calendar.values_at(i) }.flatten.compact.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == Time.zone.parse("#{@sunday+i.days}")
        Time.zone.parse(hash['end']).should == Time.zone.parse("#{@sunday+i.days} 9:00")
      end

      odd.collect{ |i| @not_calendar.values_at(i) }.flatten.compact.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == Time.zone.parse("#{@sunday + i.days} 17:00")
        Time.zone.parse(hash['end']).should == Time.zone.parse("#{@sunday + (i+1).days}")
      end
      
      # should set calendar objects title to ''
      @not_calendar.each do |hash|
        hash['title'].should == ''
      end
    end

    it "should build calendar object using multiple rules on the same day" do
      @facility   = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      # create rule tue 1 am - 3 am
      @options    = Hash[:on_mon => false, :on_tue => true, :on_wed => false, :on_thu => false, :on_fri => false, :on_sat => false, :on_sun => false,
                         :start_hour => 1, :start_min => 0, :end_hour => 3, :end_min => 0,
                         :duration_mins => 60, :discount_percent => 0]
      @rule1      = @instrument.schedule_rules.create(@options)
      assert @rule1.valid?
      # create rule tue 7 am - 9 am
      @options    = Hash[:on_mon => false, :on_tue => true, :on_wed => false, :on_thu => false, :on_fri => false, :on_sat => false, :on_sun => false,
                         :start_hour => 7, :start_min => 0, :end_hour => 9, :end_min => 0,
                         :duration_mins => 60, :discount_percent => 0]
      @rule2      = @instrument.schedule_rules.create(@options)
      assert @rule2.valid?

      # find past tuesday, and build calendar objects
      @tuesday    = ScheduleRule.sunday_last + 2.days

      # times should be tue 1 am - 3 am
      @calendar1  = @rule1.as_calendar_object(:start_date => :sunday_last)
      @calendar1.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == (@tuesday + 1.hour)
        Time.zone.parse(hash['end']).should == (@tuesday + 3.hours)
      end

      # times should be tue 7 am - 9 am
      @calendar2  = @rule2.as_calendar_object(:start_date => :sunday_last)
      @calendar2.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == (@tuesday + 7.hours)
        Time.zone.parse(hash['end']).should == (@tuesday + 9.hours)
      end

      # build not available rules from the available rules collection, 3 for tue and 1 each for rest of days
      @not_available = ScheduleRule.unavailable([@rule1, @rule2])
      @not_available.size.should == 9
      @not_calendar  = @not_available.collect{ |na| na.as_calendar_object(:start_date => :sunday_last) }.flatten
      
      # rules for tuesday should be 12am-1am, 3am-7am, 9pm-12pm
      @tuesday_times = @not_calendar.select{ |hash| Time.zone.parse(hash['start']).to_date == @tuesday }.collect do |hash|
        [Time.zone.parse(hash['start']).hour, Time.zone.parse(hash['end']).hour]
      end
      @tuesday_times.should == [[0,1], [3,7], [9,0]]
      
      # rules for other days should be 12am-12pm
      @other_times = @not_calendar.select{ |hash| Time.zone.parse(hash['start']).to_date != @tuesday }.collect do |hash|
        [Time.zone.parse(hash['start']).hour, Time.zone.parse(hash['end']).hour]
      end
      @other_times.should == [[0,0], [0,0], [0,0], [0,0], [0,0], [0,0]]
    end

    it "should build calendar object using adjacent rules across days" do
      @facility   = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      # create rule tue 9 pm - 12 am
      @options    = Hash[:on_mon => false, :on_tue => true, :on_wed => false, :on_thu => false, :on_fri => false, :on_sat => false, :on_sun => false,
                         :start_hour => 21, :start_min => 0, :end_hour => 24, :end_min => 0,
                         :duration_mins => 60, :discount_percent => 0]
      @rule1      = @instrument.schedule_rules.create(@options)
      assert @rule1.valid?
      # create rule wed 12 am - 9 am
      @options    = Hash[:on_mon => false, :on_tue => false, :on_wed => true, :on_thu => false, :on_fri => false, :on_sat => false, :on_sun => false,
                         :start_hour => 0, :start_min => 0, :end_hour => 9, :end_min => 0,
                         :duration_mins => 60, :discount_percent => 0]
      @rule2      = @instrument.schedule_rules.create(@options)
      assert @rule2.valid?

      # find past tuesday, and build calendar objects
      @tuesday    = ScheduleRule.sunday_last + 2.days
      @wednesday  = @tuesday + 1.day

      # times should be tue 9 pm - 12 am
      @calendar1  = @rule1.as_calendar_object(:start_date => :sunday_last)
      @calendar1.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == (@tuesday + 21.hours)
        Time.zone.parse(hash['end']).should == (@tuesday + 24.hours)
      end

      # times should be tue 12 am - 9 am
      @calendar2  = @rule2.as_calendar_object(:start_date => :sunday_last)
      @calendar2.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == (@wednesday + 0.hours)
        Time.zone.parse(hash['end']).should == (@wednesday + 9.hours)
      end
    end

    it "should build calendar object using start date" do
      @facility   = Factory.create(:facility)
      @facility_account = @facility.facility_accounts.create(Factory.attributes_for(:facility_account))
      @instrument = @facility.instruments.create(Factory.attributes_for(:instrument, :facility_account_id => @facility_account.id))
      # create rule every day from 9 am to 5 pm
      @rule       = @instrument.schedule_rules.create(Factory.attributes_for(:schedule_rule))
      assert @rule.valid?
      
      # set start_date as wednesday
      @wednesday  = ScheduleRule.sunday_last + 3.days
      @calendar   = @rule.as_calendar_object(:start_date => @wednesday)
      
      # should start on wednesday
      @calendar.size.should == 7
      Time.zone.parse(@calendar[0]['start']).to_date.should == @wednesday
    end
  end
  
end
