class GeneralReportsController < ReportsController


  def product
    render_report(0, 'Name') {|od| od.product.name }
  end


  def account
    render_report(1, 'Description') {|od| od.account.to_s }
  end


  def account_owner
    render_report(2, 'Name') do |od|
      owner=od.account.owner.user
      "#{owner.full_name} (#{owner.username})"
    end
  end


  def purchaser
    render_report(3, 'Name') do |od|
      usr=od.order.user
      "#{usr.full_name} (#{usr.username})"
    end
  end


  def price_group
    render_report(4, 'Name') {|od| od.price_policy ? od.price_policy.price_group.name : 'Unassigned' }
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
    page_report(rows)
  end
  
  
  def report_data
    fulfilled_stati=[ OrderStatus.complete.first.id, OrderStatus.reconciled.first.id ]
    fulfilled_ods=report_data_query(fulfilled_stati & @status_ids, 'order_details.fulfilled_at')
    ordered_ods=report_data_query(@status_ids - fulfilled_stati, 'orders.ordered_at')
    fulfilled_ods + ordered_ods
  end


  def report_data_query(stati, date_column)
    return [] if stati.blank?

    OrderDetail.joins(:order_status).
                where('order_statuses.id' => stati).
                joins('LEFT JOIN orders ON order_details.order_id = orders.id').
                where("orders.facility_id = ? AND #{date_column} >= ? AND #{date_column} <= ?", current_facility.id, @date_start, @date_end).
                includes(:order, :account, :price_policy, :product).
                all
  end

end
