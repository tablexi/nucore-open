require 'spec_helper'

describe DateHelper do

  describe "#parse_usa_date" do

    context "passed bad dates" do
      ["05012012", "somegarbage", ""].each do |bad_date_string|
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

    end

    it "should do something with extra_date_info (unknown)"
  end

  describe "#human_date"
  describe "#human_time"

end
