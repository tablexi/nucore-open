class ReportsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :setup_dates

  load_and_authorize_resource :class => ReportsController


  def initialize
    @active_tab = 'admin_reports'
    super
  end


  def index
    redirect_to product_facility_reports_path
  end


  def product
    render_general_report 0, 'Name' do
      [ [ 'Product', '23', '100' ] ]
    end
  end


  def account
    render_general_report 1, 'Account' do
      [ [ 'Account', '24', '3100' ] ]
    end
  end


  def account_owner
    render_general_report 2, 'Owner' do
      [ [ 'Owner', '26', '1000' ] ]
    end
  end


  def purchaser
    render_general_report 3, 'Purchaser' do
      [ [ 'Purchaser', '66', '9000' ] ]
    end
  end


  def price_group
    render_general_report 4, 'Price Group' do
      [ [ 'Price Group', '62', '15000' ] ]
    end
  end

  
  def instrument_utilization
    render_report_download 'instrument_utilization' do
      Reservation.where(%q/reserve_start_at >= ? AND reserve_start_at <= ? AND canceled_at IS NULL AND (order_details.state IS NULL OR order_details.state = 'complete')/, @date_start, @date_end)
                 .joins('LEFT JOIN order_details ON reservations.order_detail_id = order_details.id')
                 .includes(:order, :order_detail, :account, :instrument)
                 .order('reserve_start_at ASC')
    end
  end


  def product_order_summary
    render_report_download 'product_order_summary' do
      OrderDetail.where(%q/order_details.state = 'complete' AND orders.ordered_at >= ? AND orders.ordered_at <= ?/, @date_start, @date_end)
                 .joins('LEFT JOIN orders ON order_details.order_id = orders.id')
                 .includes(:order, :account, :price_policy, :product)
                 .order('orders.ordered_at ASC')
    end
  end


  private

  def setup_dates
    if request.post?
      @date_start    = parse_usa_date(params[:date_start])
      @date_end      = parse_usa_date(params[:date_end])
    else
      now         = Date.today
      @date_start = Date.new(now.year, now.month, 1) - 1.month
      @date_end   = @date_start + 42.days
      @date_end   = Date.new(@date_end.year, @date_end.month) - 1.day
    end
  end


  def render_general_report(tab_index, *front_th)
    @rows=yield
    @selected_index=tab_index
    @headers=front_th + [ 'Quantity', 'Total Cost' ]

    respond_to do |format|
      format.js { render :action => 'general_report' }
      format.html { render :action => 'general_report' }
    end
  end


  def render_report_download(report_prefix)
    @reportables = yield.all

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
