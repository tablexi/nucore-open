require 'spec_helper'
describe SettingsHelper do
  # Make sure we return the Settings to the default state after each test
  after :each do
    Settings.reload!
  end

  context 'fiscal year' do
    before :each do
      Settings.financial.fiscal_year_begins = '03-01'
    end
    it 'should get the right fiscal year for a year' do
      SettingsHelper::fiscal_year(2020).should == Time.zone.parse('2020-03-01').beginning_of_day
      # Make sure our parsing is happening correctly (i.e. it's not mixing up the month and day)
      SettingsHelper::fiscal_year(2020).strftime('%b %-d %Y').should == 'Mar 1 2020'
    end
    it 'should get the previous year for dates before the start' do
      SettingsHelper::fiscal_year_beginning(DateTime.new(2010, 2, 5)).should == Time.zone.parse('2009-03-01').beginning_of_day
      # Make sure we can compare either DateTime or Time
      SettingsHelper::fiscal_year_beginning(Time.zone.parse('2010-02-05')).should == Time.zone.parse('2009-03-01').beginning_of_day
    end
    it 'should the the next year for dates after the start' do
      SettingsHelper::fiscal_year_beginning(DateTime.new(2010, 5, 5)).should == Time.zone.parse('2010-03-01').beginning_of_day
    end
    it 'should set the end of the fiscal year for dates before the start' do
      SettingsHelper::fiscal_year_end(DateTime.new(2014, 2, 5)).should == Time.zone.parse('2014-02-28').end_of_day
    end
    it 'should set the end of the fiscal year for dates after the start' do
      SettingsHelper::fiscal_year_end(DateTime.new(2014, 5, 14)).should == Time.zone.parse('2015-02-28').end_of_day
    end
  end

end