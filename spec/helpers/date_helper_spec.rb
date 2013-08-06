require 'spec_helper'

describe DateHelper do

  describe "#parse_usa_date" do

    context "passed bad dates" do
      ["05012012", "somegarbage", "11/31/2012", nil, '9/'].each do |bad_date_string|
        it "should not raise error for: #{bad_date_string}" do
          lambda { parse_usa_date(bad_date_string) }.should_not raise_error
        end

        it "should return nil for #{bad_date_string}" do
          parse_usa_date(bad_date_string).should be_nil
        end
      end
    end

    context "passed valid dates" do
      it "parse a usa formatted date properly" do
        parse_usa_date("05/10/2012").should == Time.zone.parse("2012-05-10")
      end

      it "parses a usa formatted date with single digits properly" do
        parse_usa_date("5/1/2012").should == Time.zone.parse('2012-05-01')
      end

      it 'should truncate a date with more than four digits in year' do
        parse_usa_date('5/1/20114').should == Time.zone.parse('2011-05-01')
      end

    end

    it "should do something with extra_date_info (unknown)"
  end

  describe "#human_date"
  describe "#human_time"

  describe 'time_ceil' do
    it 'rounds up to the nearest 5 minute' do
      time_ceil(Time.zone.parse('2013-08-15 12:03')).should == Time.zone.parse('2013-08-15 12:05')
    end

    it 'drops the seconds before rounding' do
      time_ceil(Time.zone.parse('2013-08-15 12:05:30')).should == Time.zone.parse('2013-08-15 12:05')
    end

    it 'does not round up if already at 5 minutes' do
      time_ceil(Time.zone.parse('2013-08-15 12:05')).should == Time.zone.parse('2013-08-15 12:05')
    end

    it 'rounds up to 15 minute' do
      time_ceil(Time.zone.parse('2013-08-15 12:05'), 15.minutes).should == Time.zone.parse('2013-08-15 12:15')
    end

    it 'rounds up to an hour' do
      time_ceil(Time.zone.parse('2013-08-15 12:05'), 1.hour).should == Time.zone.parse('2013-08-15 13:00')
    end
  end

end
