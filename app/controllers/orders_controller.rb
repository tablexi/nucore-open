class OrdersController < ApplicationController
  customer_tab  :all

  before_filter :authenticate_user!
  before_filter :check_acting_as,          :except => [:cart, :add, :choose_account, :show, :remove, :purchase, :update_or_purchase, :receipt, :update]
  before_filter :init_order,               :except => [:cart, :index, :receipt]
  before_filter :protect_purchased_orders, :except => [:cart, :receipt, :confirmed, :index]

  def initialize
    @active_tab = 'orders'
    super
  end

  def init_order
    @order = Order.find(params[:id])
  end

  def protect_purchased_orders
    if @order.state == 'purchased'
      redirect_to receipt_order_path(@order) and return
    end
  end

  # GET /orders/cart
  def cart
    @order = acting_user.cart(session_user)
    redirect_to order_path(@order) and return
  end

  # GET /orders/:id
  def show
    load_statuses
    facility_ability = Ability.new(session_user, @order.facility, self)
    @order.being_purchased_by_admin = facility_ability.can?(:act_as, @order.facility)
    @order.validate_order! if @order.new?
  end

  # PUT /orders/:id/clear
  def clear
    @order.clear!
    redirect_to order_path(@order) and return
  end

  # GET /orders/2/add/
  # PUT /orders/2/add/
  def add
    ## get items to add from the form post or from the session
    ods_from_params = (params[:order].presence and params[:order][:order_details].presence) || []
    items =  ods_from_params.presence || session[:add_to_cart].presence || []
    session[:add_to_cart] = nil


    # ignore ods w/ empty or 0 quantities
    items = items.select { |od| od.is_a?(Hash) and od[:quantity].present? and (od[:quantity] = od[:quantity].to_i) > 0 }
    return redirect_to(:back, :notice => "Please add at least one quantity to order something") unless items.size > 0

    first_product = Product.find(items.first[:product_id])
    facility_ability = Ability.new(session_user, first_product.facility, self)

    # if acting_as, make sure the session user can place orders for the facility
    if acting_as? && facility_ability.cannot?(:act_as, first_product.facility)
      flash[:error] = "You are not authorized to place an order on behalf of another user for the facility #{current_facility.try(:name)}."
      redirect_to order_path(@order) and return
    end



    ## handle a single instrument reservation
    if items.size == 1 and (quantity = items.first[:quantity].to_i) == 1 #only one od w/ quantity of 1
      if first_product.respond_to?(:reservations)                              # and product is reservable

        # make a new cart w/ instrument (unless this order is empty.. then use that one)
        @order = acting_user.cart(session_user, @order.order_details.empty?)

        # wipe out stale account info in temp cart to avoid account related errors
        @order.account = nil
        @order.account_id = nil

        @order.add(first_product, 1)

        # bypass cart kicking user over to new reservation screen
        return redirect_to new_order_order_detail_reservation_path(@order.id, @order.order_details.first)
      end
    end

    ## make sure the order has an account
    if @order.account.nil?
      ## add auto_assign back here if needed

      ## save the state to the session and redirect
      session[:add_to_cart] = items
      redirect_to choose_account_order_path(@order) and return
    end

    ## process each item
    @order.transaction do
      items.each do |item|
        @product = Product.find(item[:product_id])
        begin
          @order.add(@product, item[:quantity])
          @order.invalidate! ## this is because we just added an order_detail
        rescue NUCore::MixedFacilityCart
          @order.errors.add(:base, "You can not add a product from another facility; please clear your cart or place a separate order.")
        rescue => e
          @order.errors.add(:base, "An error was encountered while adding the product #{@product}.")
          Rails.logger.error(e.message)
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end

      if @order.errors.any?
        flash[:error] = "There were errors adding to your cart:<br>#{@order.errors.full_messages.join('<br>')}".html_safe
        raise ActiveRecord::Rollback
      end
    end

    redirect_to order_path(@order)
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

    redirect_to params[:redirect_to].presence || order_path(@order)

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
            @order.update_attributes!(:account => account)
          rescue => e
            success = false
            raise ActiveRecord::Rollback
          end
        end
      end

      if success
        if session[:add_to_cart].nil?
          redirect_to cart_path
        else
          redirect_to add_order_path(@order)
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
      @product = @order.order_details[0].try(:product)
    else
      @product = Product.find(session[:add_to_cart].first[:product_id])
    end

    redirect_to(cart_path) && return unless @product

    @accounts = acting_user.accounts.for_facility(@product.facility).active
    @errors   = {}
    details   = @order.order_details
    @accounts.each do |account|
      if session[:add_to_cart] and
         ods = session[:add_to_cart].presence and
         product_id = ods.first[:product_id]
        error = account.validate_against_product(Product.find(product_id), acting_user)
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


  # PUT /orders/:id/update (submission from a cart)
  def update_or_purchase
    # if update button was clicked
    if params[:commit] == "Update"
      update
    else
      purchase
    end
  end

  # PUT /orders/:id/update
  def update
    load_statuses
    params[:order_datetime] = build_order_date if acting_as?
    @order.transaction do
      if update_order_details
        render :show
        # redirect_to order_path(@order)
      else
        logger.debug "errors #{@order.errors.full_messages}"
        flash[:error] = @order.errors.full_messages.join("<br/>").html_safe
        return render :show
      end
    end
  end

  # PUT /orders/1/purchase
  def purchase
    facility_ability = Ability.new(session_user, @order.facility, self)
    #revalidate the cart, but only if the user is not an admin
    @order.being_purchased_by_admin = facility_ability.can?(:act_as, @order.facility)

    @order.ordered_at = build_order_date if params[:order_date].present? && params[:order_time].present? && acting_as?

    begin
      @order.transaction do
        # try update
        quantities_before = @order.order_details.order("order_details.id").collect(&:quantity)
        if update_order_details
          quantities_after = @order.order_details.order("order_details.id").collect(&:quantity)

          if quantities_after != quantities_before
            flash[:notice] = "Quantities have changed, please review updated prices then click \"Purchase\""
            return redirect_to order_path(@order)
          end
        else
          logger.debug "errors #{@order.errors.full_messages}"
          flash[:error] = @order.errors.full_messages.join("<br/>").html_safe
          return render :show
        end

        # Empty message because validate_order! and purchase! don't give us useful messages as to why they failed
        raise NUCore::PurchaseException.new("") unless @order.validate_order! && @order.purchase!

        if facility_ability.can? :order_in_past, @order
          raise NUCore::PurchaseException.new(I18n.t('controllers.orders.purchase.future_dating_error')) unless @order.can_backdate_order_details?

          # update order detail statuses if you've changed it while acting as
          if acting_as? && params[:order_status_id].present?
            @order.backdate_order_details!(session_user, params[:order_status_id])
          else
            @order.complete_past_reservations!
          end
        end

        Notifier.order_receipt(:user => @order.user, :order => @order).deliver if should_send_notification?

        # If we're only making a single reservation, we'll redirect
        if @order.order_details.size == 1 && @order.order_details[0].product.is_a?(Instrument) && !@order.order_details[0].bundled? && !acting_as?
          od=@order.order_details[0]

          if od.reservation.can_switch_instrument_on?
            redirect_to order_order_detail_reservation_switch_instrument_path(@order, od, od.reservation, :switch => 'on', :redirect_to => reservations_path)
          else
            redirect_to reservations_path
          end

          flash[:notice]='Reservation completed successfully'
        else
          redirect_to receipt_order_path(@order)
        end

        return
      end
    rescue => e
      flash[:error] = I18n.t('orders.purchase.error')
      flash[:error] += " #{e.message}" if e.message
      puts e.message
      @order.reload.invalidate!
      redirect_to order_path(@order) and return
    end
  end

  # GET /orders/1/receipt
  def receipt
    @order = Order.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @order.purchased?

    @order_details = @order.order_details.select{|od| od.can_be_viewed_by?(acting_user) }
    raise ActiveRecord::RecordNotFound if @order_details.empty?

    @accounts = @order_details.collect(&:account).uniq
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

  private

  def update_order_details
    # don't run if no updates for order_details

    order_detail_updates = {}
    params.each do |key, value|
      if /^(quantity|note)(\d+)$/ =~ key and value.present?
        order_detail_updates[$2.to_i] ||= Hash.new
        order_detail_updates[$2.to_i][$1.to_sym] = value
      end
    end

    return @order.update_details(order_detail_updates)
  end

  def build_order_date
    if params[:order_date].present? && params[:order_time].present?
      parse_usa_date(params[:order_date], join_time_select_values(params[:order_time]))
    end
  end

  def load_statuses
    @order_statuses = OrderStatus.non_protected_statuses(@order.facility)
  end

  def should_send_notification?
    !acting_as? || params[:send_notification] == '1'
  end
end
