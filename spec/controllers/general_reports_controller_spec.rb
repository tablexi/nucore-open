require 'spec_helper'
require 'controller_spec_helper'
require 'report_spec_helper'

describe GeneralReportsController do
  include ReportSpecHelper


  run_report_tests([
    { :action => :product, :index => 0, :report_on_label => 'Name', :report_on => Proc.new{|od| od.product.name} },
    { :action => :account, :index => 1, :report_on_label => 'Description', :report_on => Proc.new{|od| od.account.to_s} },
    { :action => :account_owner, :index => 2, :report_on_label => 'Name', :report_on => Proc.new{|od| owner=od.account.owner.user; "#{owner.last_name}, #{owner.first_name} (#{owner.username})"} },
    { :action => :purchaser, :index => 3, :report_on_label => 'Name', :report_on => Proc.new{|od| usr=od.order.user; "#{usr.last_name}, #{usr.first_name} (#{usr.username})"} },
    { :action => :price_group, :index => 4, :report_on_label => 'Name', :report_on => Proc.new{|od| od.price_policy ? od.price_policy.price_group.name : 'Unassigned'} }
  ])


  private

  def setup_extra_params(params)
    params.merge!(:status_filter => [ OrderStatus.complete.first.id ])
  end


  def report_headers(label)
    if !export_all_request?
      headers=[ label, 'Quantity', 'Total Cost', 'Percent of Cost' ]
    else
      headers=[
        'Order', 'Ordered At', 'Fulfilled At', 'Order Status', 'Order State',
        'Ordered By', 'First Name', 'Last Name', 'Email', 'Product ID', 'Product Type',
        'Product', 'Quantity', 'Bundled Products', 'Account Type', 'Affiliate', 'Account',
        'Account Description', 'Account Expiration', 'Account Owner', 'Owner First Name',
        'Owner Last Name', 'Owner Email', 'Price Group', 'Estimated Cost', 'Estimated Subsidy',
        'Estimated Total', 'Actual Cost', 'Actual Subsidy', 'Actual Total', 'Reservation Start Time', 
        'Reservation End Time', 'Reservation Minutes', 'Actual Start Time', 'Actual End Time', 
        'Actual Minutes', 'Disputed At', 'Dispute Reason', 'Dispute Resolved At', 'Dispute Resolved Reason',
        'Reviewed At', 'Statemented On', 'Journal Date', 'Reconciled Note'
      ]
    end

    headers
  end


  def assert_report_params_init
    super
    assigns(:status_ids).should be_instance_of Array

    if @params[:date_start].blank? && @params[:date_end].blank?
      stati=[ OrderStatus.complete.first, OrderStatus.reconciled.first ]
    elsif @params[:status_filter].blank?
      stati=[]
    else
      stati=@params[:status_filter].collect{|si| OrderStatus.find(si.to_i) }
    end

    status_ids=[]

    stati.each do |stat|
      status_ids << stat.id
      status_ids += stat.children.collect(&:id) if stat.root?
    end

    assigns(:status_ids).should == status_ids
  end


  def assert_report_init(label)
    assigns(:total_quantity).should be_instance_of Fixnum
    assigns(:total_cost).should be_instance_of Float

    rows, ods=assigns(:rows), OrderDetail.all
    rows.size.should == ods.size

    rows.each do |row|
      row.should be_instance_of Array
      row.size.should == 4
    end

    ods.sort!{|a,b| yield(a) <=> yield(b) }

    ods.each_with_index do |od, i|
      rows[i][0].should == yield(od)
      rows[i][1].should == od.quantity
      rows[i][2].should == od.total.to_i
      rows[i][3].should == to_percent(od.total / assigns(:total_cost))
    end
  end


  def assert_report_data_init(label)
    assigns(:report_on).should be_instance_of Proc
    assigns(:report_data).should == OrderDetail.all
  end

end
