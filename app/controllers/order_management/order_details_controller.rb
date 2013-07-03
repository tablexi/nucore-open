class OrderManagement::OrderDetailsController < ApplicationController
  load_resource :facility, :find_by => :url_name
  load_resource :order, :through => :facility
  load_resource :order_detail, :through => :order

  before_filter :authorize_order_detail
  before_filter :load_accounts, :only => [:edit]
  before_filter :load_order_statuses, :only => [:edit]

  def edit
    render :layout => false if request.xhr?
  end

  def pricing
    checker = OrderDetails::PriceChecker.new(@order_detail)
    @prices = checker.prices_from_params(params[:order_detail])

    render :json => @prices.to_json
  end

  private

  def ability_resource
    @order_detail
  end

  def authorize_order_detail
    authorize! :update, @order_detail
  end

  def load_accounts
    @available_accounts = @order.user.accounts.to_a
    @available_accounts << @order.account unless @available_accounts.include?(@order.account)
  end

  def load_order_statuses
    @order_statuses = if @order_detail.can_reconcile?
      [ OrderStatus.complete.first, OrderStatus.cancelled.first, OrderStatus.reconciled.first ]
    elsif @order_detail.complete?
      [ OrderStatus.complete.first, OrderStatus.cancelled.first ]
    else
      OrderStatus.non_protected_statuses(current_facility)
    end
  end

end