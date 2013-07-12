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

  def files
    @files = @order_detail.stored_files.sample_result.order(:created_at)
    render :layout => false if request.xhr?
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
    return if @order_detail.reconciled?

    if @order_detail.complete?
      @order_statuses = [ OrderStatus.complete.first, OrderStatus.cancelled.first ]
      @order_statuses << OrderStatus.reconciled.first if @order_detail.can_reconcile?
    else
      @order_statuses = OrderStatus.non_protected_statuses(current_facility)
    end
  end

  def add_can_edit
    @order_detail.class.define_method :edit_disabled? do
      self.in_open_journal? || self.reconciled?
    end
  end

end