class ReportsController < ApplicationController
  include ReportsHelper
  include CSVHelper

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_report_params

  load_and_authorize_resource :class => ReportsController


  def initialize
    @active_tab = 'admin_reports'
    super
  end


  private

  def format_username(user)
    name=''
    name += (user.last_name || '')
    name += ", " unless name.blank?
    name += (user.first_name || '')
    "#{name} (#{user.username})"
  end


  def init_report_params
    @date_start = params[:date_start].presence && parse_usa_date(params[:date_start])
    if @date_start.blank?
      @date_start = (Time.zone.now - 1.month).beginning_of_month
    else
      @date_start=parse_usa_date(params[:date_start]).beginning_of_day
    end

    @date_end = params[:date_end].presence && parse_usa_date(params[:date_end])
    if @date_end.blank?
      @date_end=@date_start + 42.days
      @date_end=Date.new(@date_end.year, @date_end.month) - 1.day
    else
      @date_end=@date_end.end_of_day
    end
  end


  def init_report(report_on_label, &report_on)
    raise 'Subclass must implement!'
  end


  def init_report_data(report_on_label, &report_on)
    raise 'Subclass must implement!'
  end


  def init_report_headers(report_on_label)
    raise 'Subclass must implement!'
  end


  def page_report(rows)
    page_size=25
    page=params[:page].blank? || rows.size < page_size ? 1 : params[:page].to_i
    #page=1 if (rows.size / page_size).to_i < page

    @rows=WillPaginate::Collection.create(page, page_size) do |pager|
      pager.replace rows[ pager.offset, pager.per_page ]
      pager.total_entries=rows.size unless pager.total_entries
    end
  end


  def render_report(tab_index, report_on_label, &report_on)
    @selected_index=tab_index
    init_report_headers report_on_label

    respond_to do |format|
      format.js do
        init_report(report_on_label, &report_on)
        render :template => 'reports/report_table'
      end

      format.html { render :template => 'reports/report' }

      format.csv do
        export_type=params[:export_id]

        case export_type
          when nil, ''
            raise 'Export type not found'
          when 'report'
            init_report(report_on_label, &report_on)
          when 'report_data'
            @report_on=report_on
            init_report_data(report_on_label, &report_on)
        end

        render_csv("#{action_name}_#{export_type}", export_type)
      end
    end
  end


  def render_report_download(report_prefix)
    @reportables = yield

    respond_to do |format|
      format.html
      format.csv { render_csv(report_prefix) }
    end
  end


  def render_csv(filename = nil, action=nil)
    filename ||= params[:action]
    filename += "_#{@date_start.strftime("%Y%m%d")}-#{@date_end.strftime("%Y%m%d")}.csv"

    set_csv_headers(filename)

    render :template => "reports/#{action ? action : action_name}", :layout => false
  end


  def report_data_request?
    params[:export_id] && params[:export_id] == 'report_data'
  end

end