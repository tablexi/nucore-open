class ReportsController < ApplicationController
  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility

  load_and_authorize_resource :class => ReportsController

  layout 'two_column'

  def initialize
    @active_tab = 'admin_reports'
    super
  end

  def index
    flash.now[:notice] = "This page is still in development"
  end

  def instrument_utilization
    if request.post?
      @date_start   = parse_usa_date(params[:date_start])
      @date_end     = parse_usa_date(params[:date_end])
      @reservations = Reservation.find(:all,
                       :conditions => [%q/reserve_start_at >= ? AND reserve_start_at <= ? AND canceled_at IS NULL AND (order_details.state IS NULL OR order_details.state = 'complete')/, @date_start, @date_end],
                       :joins => ['LEFT JOIN order_details ON reservations.order_detail_id = order_details.id'],
                       :include => [:order, :order_detail, :account, :instrument],
                       :order => ['reserve_start_at ASC'])

      respond_to do |format|
        format.csv { render_csv("instrument_utilization_#{@date_start.strftime("%Y%m%d")}-#{@date_end.strftime("%Y%m%d")}") }
      end
    else
      now         = Date.today
      @date_start = Date.new(now.year, now.month, 1) - 1.month
      @date_end   = @date_start + 42.days
      @date_end   = Date.new(@date_end.year, @date_end.month) - 1.day
    end
  end

  def product_order_summary
    if request.post?
      @date_start    = parse_usa_date(params[:date_start])
      @date_end      = parse_usa_date(params[:date_end])
      @order_details = OrderDetail.find(:all,
                       :conditions => [%q/order_details.state = 'complete' AND orders.ordered_at >= ? AND orders.ordered_at <= ?/, @date_start, @date_end],
                       :joins => ['LEFT JOIN orders ON order_details.order_id = orders.id'],
                       :include => [:order, :account, :price_policy, :product],
                       :order => ['orders.ordered_at ASC'])

      respond_to do |format|
        format.csv { render_csv("product_order_summary_#{@date_start.strftime("%Y%m%d")}-#{@date_end.strftime("%Y%m%d")}") }
      end
    else
      now         = Date.today
      @date_start = Date.new(now.year, now.month, 1) - 1.month
      @date_end   = @date_start + 42.days
      @date_end   = Date.new(@date_end.year, @date_end.month) - 1.day
    end
  end

  private

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
