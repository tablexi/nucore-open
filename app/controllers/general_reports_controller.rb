class GeneralReportsController < ReportsController

  def report_by
    key = params[:report_by].to_sym
    index = reports.keys.find_index(key)
    header = key == :account ? "Description" : "Name" # TODO refactor
    render_report(index, header, &reports[key])
  end

  private

  private

  def reports
    @reports ||= {
      product: -> (od) { od.product.name },
      account: :account,
      account_owner: method(:account_owner_group),
      purchaser: -> (od) { format_username od.order.user },
      price_group: -> (od) { od.price_policy ? od.price_policy.price_group.name : "Unassigned"  },
      assigned_to: -> (od) { od.assigned_user.presence ? format_username(od.assigned_user) : "Unassigned" }
    }
  end

  def report_keys
    reports.keys
  end
  helper_method :report_keys

  def account_owner_group(od)
    # Space at beginning is intentional to bubble it to the top of the list
    od.account.owner_user ? format_username(od.account.owner_user) : " Missing Owner for #{od.account.account_number}"
  end

  def email_to_address
    params[:email_to_address].presence || current_user.email
  end

  def generate_report_data_csv
    ExportRawReportMailer.delay.raw_report_email(email_to_address, raw_report)
    if request.xhr?
      render nothing: true
    else
      flash[:notice] = I18n.t("controllers.reports.mail_queued", email: email_to_address)
      redirect_to send("#{action_name}_facility_general_reports_path", current_facility)
    end
  end

  def raw_report
    Reports::ExportRaw.new(
      facility: current_facility,
      date_range_field: params[:date_range_field],
      date_start: @date_start,
      date_end: @date_end,
      order_status_ids: @status_ids,
    )
  end

  def init_report_params
    status_ids = Array(params[:status_filter])

    stati = if params[:date_start].blank? && params[:date_end].blank?
              # page load -- default to most interesting/common statuses
              [OrderStatus.complete.first, OrderStatus.reconciled.first]
            elsif status_ids.blank?
              # user removed all status filters. They will get nothing back but that's what they want!
              []
            else
              # user filters
              status_ids.reject(&:blank?).collect { |si| OrderStatus.find(si.to_i) }
            end

    @status_ids = []

    stati.each do |stat|
      @status_ids << stat.id
      @status_ids += stat.children.collect(&:id) if stat.root?
    end

    @date_range_field = params[:date_range_field] || "journal_or_statement_date"
    super
  end

  def init_report_headers(report_on_label = nil)
    @headers = [report_on_label, "Quantity", "Total Cost", "Percent of Cost"]
  end

  def init_report_data(_report_on_label)
    @report_data = report_data
  end

  def init_report(_report_on_label)
    sums = {}
    rows = []
    @total_quantity = 0
    @total_cost = 0.0
    report_data.each do |od|
      key = yield od

      key = "Undefined" if key.blank?

      sums[key] = [0, 0] unless sums.key?(key)
      sums[key][0] += od.quantity
      @total_quantity += od.quantity

      total = od.total
      # total can be nil, in which case don't add to cost
      # stats. Report remains true but can appear off since
      # quantity goes up but not cost.
      if total
        sums[key][1] += total
        @total_cost += total
      end
    end

    sums.each do |k, v|
      percent_cost = to_percent(@total_cost > 0 ? v[1] / @total_cost : 1)
      rows << v.push(percent_cost).unshift(k)
    end

    rows.sort! { |a, b| a.first <=> b.first }

    page_report(rows)
  end

  def report_data
    @report_data = report_data_query(@status_ids, @date_range_field)
  end

  def report_data_query(order_status_id, date_range_field)
    Reports::Querier.new(
      order_status_id: order_status_id,
      current_facility: current_facility,
      date_range_field: date_range_field,
      date_range_start: @date_start,
      date_range_end: @date_end,
    ).perform
  end

end
