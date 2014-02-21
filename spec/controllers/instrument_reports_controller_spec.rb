require 'spec_helper'
require 'controller_spec_helper'
require 'report_spec_helper'

describe InstrumentReportsController do
  include ReportSpecHelper


  run_report_tests([
    { :action => :instrument, :index => 0, :report_on_label => nil, :report_on => Proc.new{|res| [ res.product.url_name ]} },
    { :action => :account, :index => 1, :report_on_label => 'Description', :report_on => Proc.new{|res| [ res.product.url_name, res.order_detail.account.to_s ] } },
    { :action => :account_owner, :index => 2, :report_on_label => 'Name', :report_on => Proc.new{|res| owner=res.order_detail.account.owner.user; [ res.product.url_name, "#{owner.full_name} (#{owner.username})" ] } },
    { :action => :purchaser, :index => 3, :report_on_label => 'Name', :report_on => Proc.new{|res| usr=res.order_detail.order.user; [ res.product.url_name, "#{usr.full_name} (#{usr.username})" ] } }
  ])


  private

  def setup_extra_test_data(user)
    start_at = parse_usa_date(@params[:date_start], '10:00 AM') + 10.days
    place_reservation(@authable, @order_detail, start_at)
    @reservation.actual_start_at = start_at
    @reservation.actual_end_at = start_at + 1.hour
    @order_detail.update_attribute(:fulfilled_at, start_at + 1.hour)
    assert @reservation.save(:validate => false)
  end


  def report_headers(label)
    headers=[ 'Instrument', 'Quantity', 'Reserved Time (h)', 'Percent of Reserved', 'Actual Time (h)', 'Percent of Actual Time' ]
    headers.insert(1, label) if label
    headers += report_attributes(@reservation, @instrument) if export_all_request?
    headers
  end


  def assert_report_init(label, &report_on)
    assigns(:totals).size.should == 5
    reservations=Reservation.all
    assigns(:totals)[0].should == reservations.size

    reserved_mins = reservations.map(&:duration_mins).inject(0, &:+)
    assigns(:totals)[1].should == to_hours(reserved_mins, 1)

    actual_mins = reservations.map(&:actual_duration_mins).inject(0, &:+)
    assigns(:totals)[3].should == to_hours(actual_mins, 1)

    assigns(:rows).should be_is_a Array

    # further testing in spec/models/reports/instrument_utilization_report_spec.rb
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
