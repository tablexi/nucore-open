class GeneralReportsController < ReportsController


  def product
    render_report(0, 'Name') {|od| od.product.name }
  end


  def account
    render_report(1, 'Description') {|od| od.account.to_s }
  end


  def account_owner
    render_report(2, 'Name') {|od| format_username od.account.owner.user }
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

  def init_report_params
    status_ids=params[:status_filter]

    if params[:date_start].blank? && params[:date_end].blank?
      # page load -- default to most interesting/common statuses
      stati=[ OrderStatus.complete.first, OrderStatus.reconciled.first ]
    elsif status_ids.blank?
      # user removed all status filters. They will get nothing back but that's what they want!
      stati=[]
    else
      # user filters
      stati=status_ids.collect{|si| OrderStatus.find(si.to_i) }
    end

    @status_ids=[]

    stati.each do |stat|
      @status_ids << stat.id
      @status_ids += stat.children.collect(&:id) if stat.root?
    end

    @date_range_field = params[:date_range_field] || 'journal_date'
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

    # only page results if we're not exporting
    if params[:export_id].present?
      @rows = rows
    else
      page_report(rows)
    end
  end


  def report_data
    @report_data = report_data_query(@status_ids, @date_range_field)
  end


  def report_data_query(stati, date_column)
    return [] if stati.blank?
    # default to using fulfilled_at
    result = OrderDetail.where(:order_status_id => stati).
                        for_facility(current_facility).
                        action_in_date_range(date_column, @date_start, @date_end)

    ## TODO
    # there is a bug in activerecord-oracle-enhanced 1.3.0 and rails 3.0.x that causes an ORA-01795: maximum number of expressions in a list is 1000
    # error if we're trying to join more than 1000 orders. oracle-enhanced 1.3.2 contains a fix, but only works in Rails 3.1.
    # We've removed :orders from the includes to prevent the SQL error, but it results in N+1 on orders. Make sure
    # to put it back when we upgrade to Rails 3.1/3.2

    if NUCore::Database.oracle?
      result = result.includes(:account, :price_policy, :product, :order_status)
    else
      result = result.includes(:order, :account, :price_policy, :product, :order_status)
    end

    result
  end

end
