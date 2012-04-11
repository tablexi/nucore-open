class OrdersController < ApplicationController
  customer_tab  :all

  before_filter :authenticate_user!
  before_filter :check_acting_as,          :except => [:cart, :add, :choose_account, :show, :remove, :purchase, :receipt, :update]
  before_filter :init_order,               :except => [:cart, :index]
  before_filter :protect_purchased_orders, :except => [:cart, :receipt, :confirmed, :index]

  def initialize
    @active_tab = 'orders'
    super
  end

  def init_order
    @order = acting_user.orders.find(params[:id])
  end

  def protect_purchased_orders
    if @order.state == 'purchased'
      redirect_to receipt_order_url(@order) and return
    end
  end

  # GET /orders/cart
  def cart
    @order = acting_user.cart(session_user)
    redirect_to order_path(@order) and return
  end

  # GET /orders/:id
  def show
    @order.validate_order! if @order.new?
  end

  # PUT /orders/:id/update
  def update
    order_detail_updates = {}
    params.each do |key, value|
      if /^(quantity|note)(\d+)$/ =~ key and value.present?
        order_detail_updates[$2.to_i] ||= Hash.new
        order_detail_updates[$2.to_i][$1.to_sym] = value
      end
    end
    @order.update_details(order_detail_updates)

    redirect_to order_path(@order) and return
  end

  # PUT /orders/:id/clear
  def clear
    @order.clear!
    redirect_to order_path(@order) and return
  end

  # PUT /orders/2/add/
  def add
    @quantity   = params[:quantity] || session[:add_to_cart][:quantity]
    @quantity=@quantity.to_i if @quantity.is_a?(String)
    @product_id = params[:product_id]    || session[:add_to_cart][:product_id]
    session[:add_to_cart] = nil
    @product    = Product.find(@product_id)

    if @order.account.nil?
      unless @product.is_a?(Instrument)
        # send to choose_account:
        # if it's not set in the order OR
        # payment source isn't valid for this facility
        session[:add_to_cart] = {:quantity => @quantity, :product_id => @product.id }
        return redirect_to choose_account_order_url(@order)
      end

      begin
        @order.auto_assign_account!(@product)
      rescue => e
        flash[:error]=e.message
        return redirect_to facility_path(@product.facility)
      end
    end

    # if acting_as, make sure the session use can place orders for the facility
    if acting_as? && !session_user.administrator? && !manageable_facilities.include?(@product.facility)
      flash[:error] = "You are not authorized to place an order on behalf of another user for the facility #{@product.facility.name}."
      redirect_to order_url(@order) and return
    end

    @order.transaction do
      begin
        order_detail = @order.add(@product, @quantity) # if product is a bundle, order_detail is an array of details
        @order.invalidate!
        return redirect_to new_order_order_detail_reservation_path(@order, order_detail) if @product.is_a?(Instrument)
        flash[:notice] = "#{@product.class.name} added to cart."
      rescue NUCore::MixedFacilityCart
        flash[:error] = "You can not add a product from another facility; please clear your cart or place a separate order."
      rescue Exception => e
        flash[:error] = "An error was encountered while adding the product."
        Rails.logger.error(e.backtrace.join("\n"))
        raise ActiveRecord::Rollback
      end
    end

    redirect_to order_url(@order)
  end

  # PUT /orders/:id/remove/:order_detail_id
  def remove
    order_detail = @order.order_details.find(params[:order_detail_id])

    # remove bundles
    if order_detail.group_id
      order_details = @order.order_details.find(:all, :conditions => {:group_id => order_detail.group_id})
      OrderDetail.transaction do
        if order_details.all?{|od| od.destroy}
          flash[:notice] = "The bundle has been removed."
        else
          flash[:error] = "An error was encountered while removing the bundle."
        end
      end
    # remove single products
    else
      if order_detail.destroy
        flash[:notice] = "The product has been removed."
      else
        flash[:error] = "An error was encountered while removing the product."
      end
    end

    redirect_to params[:redirect_to].presence || order_url(@order)

    # clear out account on the order if its now empty
    if  @order.order_details.empty?
      @order.account_id = nil
      @order.save!
    end
  end

  # GET  /orders/:id/choose_account
  # POST /orders/:id/choose_account
  def choose_account
    if request.post?
      begin
        account = Account.find(params[:account_id])
        raise ActiveRecord::RecordNotFound unless account.can_be_used_by?(@order.user)
      rescue
      end
      if account
        success = true
        @order.transaction do
          begin
            @order.invalidate
            @order.update_attributes!(:account_id => account.id)
            @order.order_details.each do |od|
              # update detail account
              od.update_account(account)
              od.save!
            end
          rescue
            success = false
            raise ActiveRecord::Rollback
          end
        end
      end

      if success
        if session[:add_to_cart].nil?
          redirect_to cart_url
        else
          redirect_to add_order_url(@order)
        end
        return
      else
        flash.now[:error] = account.nil? ? 'Please select a payment method.' : 'An error was encountered while selecting a payment method.'
      end
    end

    if params[:reset_account]
      @order.order_details.each do |od|
        od.account = nil
        od.save!
      end
    end

    if session[:add_to_cart].blank?
      @product = @order.order_details[0].product
    else
      @product = Product.find(session[:add_to_cart][:product_id])
    end
    @accounts = acting_user.accounts.active.for_facility(@product.facility)
    @errors   = {}
    details   = @order.order_details
    @accounts.each do |account|
      if session[:add_to_cart] && session[:add_to_cart][:product_id]
        error = account.validate_against_product(Product.find(session[:add_to_cart][:product_id]), acting_user)
        @errors[account.id] = error if error
      end
      unless @errors[account.id]
        details.each do |od|
          error = account.validate_against_product(od.product, acting_user)
          @errors[account.id] = error if error
        end
      end
    end
  end

  def add_account
    flash.now[:notice] = "This page is still in development; please add an account administratively"
  end

  # PUT /orders/1/purchase
  def purchase
    #revalidate the cart, but only if the user is not an admin
    @order.being_purchased_by_admin = session_user.operator_of? @facility
    if @order.validate_order! && @order.purchase!
      Notifier.order_receipt(:user => @order.user, :order => @order).deliver

      if @order.order_details.size == 1 && @order.order_details[0].product.is_a?(Instrument) && !@order.order_details[0].bundled?
        od=@order.order_details[0]

        if od.reservation.can_switch_instrument_on?
          redirect_to order_order_detail_reservation_switch_instrument_path(@order, od, od.reservation, :switch => 'on', :redirect_to => reservations_path)
        else
          redirect_to reservations_path
        end

        flash[:notice]='Reservation completed successfully'
      else
        redirect_to receipt_order_url(@order)
      end

      return
    else
      flash[:error] = 'Unable to place order.'
      @order.invalidate!
      redirect_to order_url(@order) and return
    end
  end

  # GET /orders/1/receipt
  def receipt
    raise ActiveRecord::RecordNotFound unless @order.purchased?
  end

  # GET /orders
  # all my orders
  def index
    # new or in process
    @order_details = session_user.order_details.non_reservations
    @available_statuses = ['pending', 'all']
    case params[:status]
    when "pending"
      @order_details = @order_details.pending
    when "all"
      @order_details = @order_details.ordered
    else
      redirect_to orders_status_path(:status => "pending")
      return
    end
    @order_details = @order_details. order('order_details.created_at DESC').paginate(:page => params[:page])
  end
  # def index_all
    # # won't show instrument order_details
    # @order_details = session_user.order_details.
      # non_reservations.
      # where("orders.ordered_at IS NOT NULL").
      # order('orders.ordered_at DESC').
      # paginate(:page => params[:page])
  # end
end
