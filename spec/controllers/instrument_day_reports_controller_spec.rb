require 'spec_helper'
require 'controller_spec_helper'
require 'report_spec_helper'

describe InstrumentDayReportsController do
  include ReportSpecHelper


  run_report_tests([
    { :action => :reserved_quantity, :index => 4, :report_on_label => nil, :report_on => Proc.new{|res| Reports::InstrumentDayReport::ReservedQuantity.new(res) } },
    { :action => :reserved_hours, :index => 5, :report_on_label => nil, :report_on => Proc.new{|res| Reports::InstrumentDayReport::ReservedHours.new(res) } },
    { :action => :actual_quantity, :index => 6, :report_on_label => nil, :report_on => Proc.new{|res| Reports::InstrumentDayReport::ActualQuantity.new(res) } },
    { :action => :actual_hours, :index => 7, :report_on_label => nil, :report_on => Proc.new{|res| Reports::InstrumentDayReport::ActualHours.new(res) } }
  ])


  private

  def setup_extra_test_data(user)
    start_at=parse_usa_date(@params[:date_start], '10:00 AM')+10.days
    place_reservation(@authable, @order_detail, start_at)
    @reservation.actual_start_at=start_at
    @reservation.actual_end_at=start_at+1.hour
    assert @reservation.save(:validate => false)
  end


  def report_headers(label)
    headers=[ 'Instrument', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' ]
    headers += report_attributes(@reservation, @instrument) if export_all_request?
    headers
  end


  def assert_report_init(label, &report_on)
    assigns(:totals).should be_is_a Array
    assigns(:totals).size.should == 7

    ndx=@reservation.actual_start_at.wday
    assigns(:totals).each_with_index do |sum, i|
      if i == ndx
        sum.should > 0
      else
        sum.should == 0
      end
    end

    instruments=Instrument.all
    assigns(:rows).should be_is_a Array
    assigns(:rows).size.should == instruments.count

    assigns(:rows).each do |row|
      row.size.should == 8
      instruments.collect(&:name).should be_include(row[0])
      row[1..-1].all?{|data| data.should be_is_a(Numeric)}
    end
  end


  def assert_report_data_init(label)
    assigns(:report_data).should == Reservation.all
  end

end
