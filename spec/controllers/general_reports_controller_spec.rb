require 'spec_helper'
require 'controller_spec_helper'
require 'report_spec_helper'

describe GeneralReportsController do
  include ReportSpecHelper


  run_report_tests([
    { :action => :product, :index => 0, :report_on_label => 'Name', :report_on => Proc.new{|od| od.product.name} },
    { :action => :account, :index => 1, :report_on_label => 'Description', :report_on => Proc.new{|od| od.account.to_s} },
    { :action => :account_owner, :index => 2, :report_on_label => 'Name', :report_on => Proc.new{|od| owner=od.account.owner.user; "#{owner.full_name} (#{owner.username})"} },
    { :action => :purchaser, :index => 3, :report_on_label => 'Name', :report_on => Proc.new{|od| usr=od.order.user; "#{usr.full_name} (#{usr.username})"} },
    { :action => :price_group, :index => 4, :report_on_label => 'Name', :report_on => Proc.new{|od| od.price_policy ? od.price_policy.price_group.name : 'Unassigned'} }
  ])


  private

  def setup_extra_params(params)
    params.merge!(:status_filter => OrderStatus.complete.first.id)
  end


  def report_headers(label)
    headers=[ label, 'Quantity', 'Total Cost', 'Percent of Cost' ]
    headers += report_attributes(@order_detail, @order) if export_all_request?
    headers
  end


  def assert_report_params_init
    super

    assigns(:status_ids).should be_instance_of Array

    os=nil

    if @params[:status_filter].blank?
      os=OrderStatus.complete.first
    elsif @params[:status_filter].to_i != -1
      os=OrderStatus.find(@params[:status_filter].to_i)
    end

    if os
      assigns(:selected_status_id).should == os.id
      order_status_ids=(os.root? ? os.children.collect(&:id) : []).push(os.id)
    else
      assigns(:selected_status_id).should == -1
      order_status_ids=OrderStatus.non_protected_statuses(@authable).collect(&:id)
    end

    assigns(:status_ids).should == order_status_ids
  end


  def assert_report_init(label)
    assigns(:total_quantity).should be_instance_of Fixnum
    assigns(:total_cost).should be_instance_of Float

    rows, ods=assigns(:rows), OrderDetail.all
    rows.should be_instance_of WillPaginate::Collection
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
    cost=0
    assigns(:report_data).each {|od| cost += od.total }
    assigns(:total_cost).should == cost
  end

end
