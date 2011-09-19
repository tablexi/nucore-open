require 'spec_helper'
require 'controller_spec_helper'
require 'report_spec_helper'

describe InstrumentReportsController do
  include ReportSpecHelper


  run_report_tests([
    { :action => :instrument, :index => 0, :report_on_label => nil, :report_on => Proc.new{|res| [ res.instrument.url_name ]} },
    { :action => :account, :index => 1, :report_on_label => 'Description', :report_on => Proc.new{|res| [ res.instrument.url_name, res.order_detail.account.to_s ] } },
    { :action => :account_owner, :index =>2, :report_on_label => 'Name', :report_on => Proc.new{|res| owner=res.order_detail.account.owner.user; [ res.instrument.url_name, "#{owner.full_name} (#{owner.username})" ] } },
    { :action => :purchaser, :index => 3, :report_on_label => 'Name', :report_on => Proc.new{|res| usr=res.order_detail.order.user; [ res.instrument.url_name, "#{usr.full_name} (#{usr.username})" ] } }
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
    headers=[ 'Instrument', 'Quantity', 'Reserved Time (h)', 'Percent of Reserved', 'Actual Time (h)', 'Percent of Actual Time' ]
    headers.insert(1, label) if label
    headers += report_attributes(@reservation, @instrument) if export_all_request?
    headers
  end


  def assert_report_init(label, &report_on)
    assigns(:totals).size.should == 3
    assigns(:totals)[0].should == Instrument.count

    reservations=Reservation.all

    reserved_hours=0
    reservations.each{|r| reserved_hours += to_hours(r.duration_mins)}
    assigns(:totals)[1].should == reserved_hours

    actual_hours=0
    reservations.each{|r| actual_hours += to_hours(r.actual_duration_mins)}
    assigns(:totals)[2].should == actual_hours

    assigns(:rows).should be_is_a Array
    assigns(:rows).each do |row|
      if label
        row.size.should == 7
        row[0].should be_is_a String
        row[1].should be_is_a String
        row[2..-1].all?{|data| data.should be_is_a Numeric}
      else
        row.size.should == 6
        row[0].should be_is_a String
        row[1..-1].all?{|data| data.should be_is_a Numeric}
      end
    end
  end


  def assert_report_data_init(label)
    reservations=Reservation.all
    assigns(:report_data).should == reservations
    assigns(:totals).should be_is_a Array

    reserved_hours,actual_hours=0,0
    reservations.each do |res|
      reserved_hours += to_hours(res.duration_mins)
      actual_hours += to_hours(res.actual_duration_mins)
    end

    assigns(:totals)[0].should == reserved_hours
    assigns(:totals)[1].should == actual_hours
  end
  
end
