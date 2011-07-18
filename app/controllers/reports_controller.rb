class ReportsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :set_report_params

  load_and_authorize_resource :class => ReportsController


  def initialize
    @active_tab = 'admin_reports'
    super
  end


  def index
    redirect_to product_facility_reports_path
  end


  def product
    render_general_report(0, 'Name') {|od| od.product.name }
  end


  def account
    render_general_report(1, 'Number') {|od| od.account.account_number }
  end


  def account_owner
    render_general_report(2, 'Username') {|od| od.account.owner.user.username }
  end


  def purchaser
    render_general_report(3, 'Username') {|od| od.order.user.username }
  end


  def price_group
    render_general_report(4, 'Name') {|od| od.price_policy ? od.price_policy.price_group.name : 'Unassigned' }
  end

  
  def product_order_summary
    render_report_download('product_order_summary') { order_details_report.order('orders.ordered_at ASC').all }
  end

  
  def instrument_utilization
    render_report_download 'instrument_utilization' do
      Reservation.where(%q/reserve_start_at >= ? AND reserve_start_at <= ? AND canceled_at IS NULL AND (order_details.state IS NULL OR order_details.state = 'complete')/, @date_start, @date_end)
                 .joins('LEFT JOIN order_details ON reservations.order_detail_id = order_details.id')
                 .includes(:order, :order_detail, :account, :instrument)
                 .order('reserve_start_at ASC')
    end
  end


  private

  def set_report_params
    @state=params[:status_filter]
    @state=OrderStatus.complete.first.name if @state.blank?

    if params[:date_start].blank?
      now=Date.today
      @date_start=Date.new(now.year, now.month, 1) - 1.month
    else
      @date_start=parse_usa_date(params[:date_start])
    end
         
    if params[:date_start].blank?
      @date_end=@date_start + 42.days
      @date_end=Date.new(@date_end.year, @date_end.month) - 1.day
    else
      @date_end=parse_usa_date(params[:date_end])
    end
  end


  def order_details_report
    OrderDetail.where('order_details.state = ? AND orders.ordered_at >= ? AND orders.ordered_at <= ?', @state, @date_start, @date_end)
               .joins('LEFT JOIN orders ON order_details.order_id = orders.id')
               .includes(:order, :account, :price_policy, :product)
  end


  def render_general_report(tab_index, front_th)
    @selected_index=tab_index

    respond_to do |format|
      format.js do
        @rows, sums, @headers=[], {}, [ front_th, 'Quantity', 'Total Cost' ]

        order_details_report.all.each do |od|
          key=yield(od)
          sums[key]=[0,0] unless sums.has_key?(key)
          sums[key][0] += od.quantity
          sums[key][1] += od.total
        end

        sums.each {|k,v| @rows << v.unshift(k) }
        @rows.sort! {|a,b| a.first <=> b.first}
        render :action => 'general_report_table'
      end

      format.html { render :action => 'general_report' }
    end
  end


  def render_report_download(report_prefix)
    @reportables = yield

    respond_to do |format|
      format.html
      format.csv { render_csv("#{report_prefix}_#{@date_start.strftime("%Y%m%d")}-#{@date_end.strftime("%Y%m%d")}") }
    end
  end


  def render_csv(filename = nil)
    filename ||= params[:action]
    filename += '.csv'

    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "text/plain"
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      headers['Expires'] = "0"
    else
      headers["Content-Type"] ||= 'text/csv'
      headers["Content-Disposition"] = "attachment; filename=\"#{filename}\""
    end

    render :layout => false
  end
end
