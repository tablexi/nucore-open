module Reports

  class InstrumentReportsController < ReportsController

    include InstrumentReporter

    def index
      @report_by = (params[:report_by].presence || "instrument")
      index = reports.keys.find_index(@report_by)
      render_report(index, header, &reports[@report_by])
    end

    def reports
      HashWithIndifferentAccess.new(
        instrument: -> (r) { [r.product.name] },
        account: -> (r) { [r.product.name, r.order_detail.account.to_s] },
        account_owner: -> (r) { [r.product.name, format_username(r.order_detail.account.owner.user)] },
        purchaser: -> (r) { [r.product.name, format_username(r.order_detail.order.user)] },
      )
    end

    private

    def header
      case @report_by
      when "account"
        "Description"
      when "instrument"
        nil
      else
        "Name"
      end
    end

    def report_keys
      reports.keys
    end
    helper_method :report_keys

    def init_report_headers(report_on_label)
      @headers = ["Instrument", "Quantity", "Reserved Time (h)", "Percent of Reserved", "Actual Time (h)", "Percent of Actual Time"]
      @headers.insert(1, report_on_label) if report_on_label
    end

    def init_report(_report_on_label, &report_on)
      report = Reports::InstrumentUtilizationReport.new(report_data)
      report.build_report &report_on

      @totals = report.totals
      @label_columns = report.key_length

      rows = report.rows
      page_report(rows)
    end

    def init_report_data(_report_on_label)
      @totals = [0, 0]
      @report_data = report_data

      @report_data.each do |res|
        @totals[0] += to_hours(res.duration_mins)
        @totals[1] += to_hours(res.actual_duration_mins)
      end

      reservation = @report_data.first
      @headers += report_attributes(reservation, reservation.product)
    end

  end

end
