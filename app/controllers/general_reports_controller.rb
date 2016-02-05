class GeneralReportsController < ReportsController


  def product
    render_report(0, 'Name') {|od| od.product.name }
  end


  def account
    render_report(1, 'Description') {|od| od.account.to_s }
  end


  def account_owner
    render_report(2, 'Name') do |od|
      # Space at beginning is intentional to bubble it to the top of the list
      od.account.owner_user ? format_username(od.account.owner_user) : " Missing Owner for #{od.account.account_number}"
    end
  end


  def purchaser
    render_report(3, 'Name') {|od| format_username od.order.user}
  end


  def price_group
    render_report(4, 'Name') {|od| od.price_policy ? od.price_policy.price_group.name : 'Unassigned' }
  end


  def assigned_to
    render_report(5, 'Name') {|od| od.assigned_user.presence ? format_username(od.assigned_user) : 'Unassigned' }
  end


  private

  def email_to_address
    params[:email_to_address].presence || current_user.email
  end

  def generate_report_data_csv
    ExportRawReportMailer.delay.raw_report_email(email_to_address, raw_report)
    if request.xhr?
      render nothing: true
    else
      flash[:notice] = I18n.t('controllers.reports.mail_queued', email: email_to_address)
      redirect_to send("#{action_name}_facility_general_reports_path", current_facility)
    end
  end

  def raw_report
    Reports::ExportRawFactory.instance(
      facility: current_facility,
      date_range_field: params[:date_range_field],
      date_start: @date_start,
      date_end: @date_end,
      order_status_ids: @status_ids,
      headers: @headers,
      action_name: action_name,
    )
  end

  def init_report_params
    status_ids = Array(params[:status_filter])

    if params[:date_start].blank? && params[:date_end].blank?
      # page load -- default to most interesting/common statuses
      stati=[ OrderStatus.complete.first, OrderStatus.reconciled.first ]
    elsif status_ids.blank?
      # user removed all status filters. They will get nothing back but that's what they want!
      stati=[]
    else
      # user filters
      stati=status_ids.reject(&:blank?).collect{|si| OrderStatus.find(si.to_i) }
    end

    @status_ids=[]

    stati.each do |stat|
      @status_ids << stat.id
      @status_ids += stat.children.collect(&:id) if stat.root?
    end

    @date_range_field = params[:date_range_field] || 'journal_or_statement_date'
    super
  end


  def init_report_headers(report_on_label)
    if !report_data_request?
      @headers=[ report_on_label, 'Quantity', 'Total Cost', 'Percent of Cost' ]
    else
      @headers=I18n.t 'controllers.general_reports.headers.data'
    end
  end


  def init_report_data(report_on_label, &report_on)
    @report_data=report_data
  end


  def init_report(report_on_label)
    sums, rows, @total_quantity, @total_cost={}, [], 0, 0.0

    report_data.each do |od|
      key=yield od

      key = "Undefined" if key.blank?

      sums[key]=[0,0] unless sums.has_key?(key)
      sums[key][0] += od.quantity
      @total_quantity += od.quantity

      total=od.total
      # total can be nil, in which case don't add to cost
      # stats. Report remains true but can appear off since
      # quantity goes up but not cost.
      if total
        sums[key][1] += total
        @total_cost += total
      end
    end

    sums.each do |k,v|
      percent_cost=to_percent(@total_cost > 0 ? v[1] / @total_cost : 1)
      rows << v.push(percent_cost).unshift(k)
    end

    rows.sort! {|a,b| a.first <=> b.first}

    page_report(rows)
  end


  def report_data
    @report_data = report_data_query(@status_ids, @date_range_field)
  end

  def report_data_query(stati, date_column)
    return [] if stati.blank?
    # default to using fulfilled_at
    result = OrderDetail.where(:order_status_id => stati)
                        .for_facility(current_facility)
                        .action_in_date_range(date_column, @date_start, @date_end)
                        .includes(:order, :account, :price_policy, :product, :order_status)
  end

end
