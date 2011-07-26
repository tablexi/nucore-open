require 'spec_helper'; require 'controller_spec_helper'

describe ReportsController do
  include DateHelper

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable=Factory.create(:facility)
    @params={
      :facility_id => @authable.url_name,
      :status_filter => OrderStatus.complete.first.name,
      :date_start => '07/08/2010',
      :date_end => '07/01/2011'
    }
  end


  context 'screen general reports' do
    before :each do
      @method=:get
    end


    context 'index' do
      before :each do
        @action=:index
      end

      it_should_allow_managers_only :redirect do
        assert_redirected_to product_facility_reports_path
      end
    end


    [
      { :action => :product, :index => 0, :report_on_label => 'Name', :report_on => Proc.new{|od| od.product.name} },
      { :action => :account, :index => 1, :report_on_label => 'Number', :report_on => Proc.new{|od| od.account.account_number} },
      { :action => :account_owner, :index => 2, :report_on_label => 'Username', :report_on => Proc.new{|od| od.account.owner.user.username} },
      { :action => :purchaser, :index => 3, :report_on_label => 'Username', :report_on => Proc.new{|od| od.order.user.username} },
      { :action => :price_group, :index => 4, :report_on_label => 'Name', :report_on => Proc.new{|od| od.price_policy ? od.price_policy.price_group.name : 'Unassigned'} }
    ].each do |test|
      context test[:action].to_s do
        before :each do
          @action=test[:action]

          [ :owner, :staff, :purchaser ].each do |buyer|
            acct=create_nufs_account_with_owner buyer
            place_and_complete_item_order(instance_variable_get("@#{buyer}"), @authable, acct)
            @order.ordered_at=parse_usa_date('12/20/2010')
            assert @order.save
          end
        end

        it_should_allow_managers_only do
          assert_general_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
        end


        context 'ajax' do
          before :each do
            @params.merge!(:format => :js)
          end

          it_should_allow :director do
            assert_general_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
          end
        end


        context 'export' do
          before :each do
            @params.merge!(:format => :csv, :export_id => 'general_report')
          end

          it_should_allow :director do
            assert_general_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
          end

          context 'export data' do
            before :each do
              @params[:export_id]='general_report_data'
            end

            it_should_allow :director do
              assert_general_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
            end
          end
        end
      end
    end
  end


  context 'old reports' do

    before :each do
      @method=:get
    end


    context 'instrument_utilization' do

      before :each do
        @action=:instrument_utilization
      end

      it_should_allow_managers_only

    end


    context 'product_order_summary' do

      before :each do
        @action=:product_order_summary
        acct=create_nufs_account_with_owner

        3.times do
          place_and_complete_item_order(@owner, @authable, acct)
          @order.ordered_at=parse_usa_date('12/20/2010')
          assert @order.save
        end
      end

      it_should_allow_managers_only do
        assert_report_params_init @params
        assigns(:reportables).should == OrderDetail.all
        should render_template 'product_order_summary'
      end


      context 'download' do

        before :each do
          @params.merge!(:format => 'csv')
        end

        it_should_allow :director, 'to download report' do
          assert_report_params_init @params
          assigns(:reportables).should == OrderDetail.all
          assert_report_download_rendered 'product_order_summary'
        end

      end
    end

  end


  private

  def assert_report_download_rendered(filename)
    @response.headers['Content-Type'].should == 'text/csv'
    filename += "_#{assigns(:date_start).strftime("%Y%m%d")}-#{assigns(:date_end).strftime("%Y%m%d")}.csv"
    @response.headers["Content-Disposition"].should == "attachment; filename=\"#{filename}\""
    should respond_with :success
  end


  def assert_report_params_init(params)
    if params[:status_filter].blank?
      assigns(:state).should == OrderStatus.complete.first.name
    else
      assigns(:state).should == params[:status_filter]
    end

    now=Date.today
    date_start=Date.new(now.year, now.month, 1) - 1.month

    if params[:date_start].blank?
      assigns(:date_start).should == date_start
    else
      assigns(:date_start).should == parse_usa_date(params[:date_start])
    end

    if params[:date_end].blank?
      date_end=date_start + 42.days
      assigns(:date_end).should == Date.new(date_end.year, date_end.month) - 1.day
    else
      assigns(:date_end).should == parse_usa_date(params[:date_end])
    end
  end


  def assert_report_headers_init(label)
    assigns(:headers).should == [ label, 'Quantity', 'Total Cost', 'Percent of Cost' ]
  end


  def assert_general_report_init(label)
    assert_report_headers_init label
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
      rows[i][3].should == ((od.total / assigns(:total_cost)) * 100)
    end
  end


  def assert_general_report_data_init(label)
    assigns(:report_on).should be_instance_of Proc
    assert_report_headers_init label
    assigns(:report_data).should == OrderDetail.all
    cost=0
    assigns(:report_data).each {|od| cost += od.total }
    assigns(:total_cost).should == cost
  end


  def assert_general_report_rendered(tab_index, label, &report_on)
    assigns(:selected_index).should == tab_index

    format=@params[:format]
    format=:html unless format

    case format
      when :html
        should render_template 'general_report'
      when :js
        assert_general_report_init label, &report_on
        should render_template 'general_report_table'
      when :csv
        export_type=@params[:export_id]

        case export_type
          when 'general_report'
            assert_general_report_init label, &report_on
          when 'general_report_data'
            assert_general_report_data_init label
        end

        assert_report_download_rendered "#{@action}_#{export_type}"
    end
  end

end
