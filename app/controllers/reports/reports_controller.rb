module Reports

  class ReportsController < ApplicationController

    include ReportsHelper
    include CSVHelper

    admin_tab     :all
    before_filter :authenticate_user!
    before_filter :check_acting_as
    before_filter :init_current_facility
    before_filter :init_report_params

    load_and_authorize_resource class: ReportsController

    delegate :reports, :format_username, to: "self.class"

    def initialize
      @active_tab = "admin_reports"
      super
    end

    def index
      @report_by = params[:report_by].presence
      index = reports.keys.find_index(@report_by)
      raise ActionController::RoutingError, "Invalid report_by" unless index
      render_report(index + tab_offset, &reports[@report_by])
    end

    def self.format_username(user)
      name = ""
      name += (user.last_name || "")
      name += ", " unless name.blank?
      name += (user.first_name || "")
      "#{name} (#{user.username})"
    end

    protected

    def tab_offset
      0
    end

    def report_by_header
      text(@report_by, default: @report_by.titleize)
    end

    private

    def init_report_params
      @date_start = parse_usa_date(params[:date_start])
      @date_start = if @date_start.blank?
                      (Time.zone.now - 1.month).beginning_of_month
                    else
                      @date_start.beginning_of_day
                    end

      @date_end = parse_usa_date(params[:date_end])
      @date_end = if @date_end.blank?
                    @date_start.end_of_month
                  else
                    @date_end.end_of_day
                  end
    end

    def init_report
      raise "Subclass must implement!"
    end

    def init_report_data
      raise "Subclass must implement!"
    end

    def init_report_headers
      raise "Subclass must implement!"
    end

    def page_report(rows)
      # Don't paginate reports if we're exporting
      @rows = if params[:export_id].present?
                rows
              else
                rows.paginate(page: params[:page], per_page: 25)
              end
    end

    def render_report(tab_index, &report_on)
      @selected_index = tab_index
      init_report_headers

      respond_to do |format|
        format.html do
          if request.xhr?
            init_report(&report_on)
            render template: "reports/report_table", layout: false
          else
            render template: "reports/report"
          end
        end

        format.csv do
          init_report(&report_on)
          render_csv("#{@report_by}_report")
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

    def render_csv(filename)
      filename += "_#{@date_start.strftime('%Y%m%d')}-#{@date_end.strftime('%Y%m%d')}.csv"
      set_csv_headers(filename)
      render template: "reports/report", layout: false
    end

    def report_data_request?
      params[:export_id] && params[:export_id] == "report_data"
    end

  end

end
