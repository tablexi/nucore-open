class OrderManagement::OrderDetailsController < ApplicationController
  load_resource :facility, :find_by => :url_name
  load_resource :order, :through => :facility
  load_resource :order_detail, :through => :order

  before_filter :authorize_order_detail
  before_filter :load_accounts, :only => [:edit, :update]
  before_filter :load_order_statuses, :only => [:edit, :update]
  before_filter :add_can_edit, :only => [:edit, :update]

  def edit
    render :layout => false if request.xhr?
  end

  def update
    updater = OrderDetails::ParamUpdater.new(@order_detail, :user => session_user, :cancel_fee => params[:with_cancel_fee] == '1')

    if updater.update_attributes(params[:order_detail])
      flash[:notice] = 'The order was successfully updated.'
      if @order_detail.updated_children.any?
        flash[:notice] << " Auto-scaled accessories have been updated as well."
        flash[:updated_order_details] = @order_detail.updated_children.map &:id
      end
      if request.xhr?
        render :nothing => true
      else
        redirect_to [current_facility, @order]
      end
    else
      flash.now[:error] = 'Error while updating order'
      render :edit, :layout => !request.xhr?, :status => 406
    end
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

  def add_can_edit
    @order_detail.class.define_method :edit_disabled? do
      self.in_open_journal? || self.reconciled?
    end
  end

end