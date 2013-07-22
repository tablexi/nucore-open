class AccessoriesController < ApplicationController
  load_resource :order
  load_resource :order_detail, :through => :order

  before_filter :authorize_order_detail
  before_filter :load_product

  def new
    accessorizer = Accessories::Accessorizer.new(@order_detail)
    @order_details = accessorizer.available_accessory_order_details
    render :layout => false if request.xhr?
  end

  def create
    accessorizer = Accessories::Accessorizer.new(@order_detail)
    @order_details = accessorizer.add_from_params(params[:accessories])

    if @order_details.none? { |od| od.errors.any? }
      @count = @order_details.count &:persisted?

      flash[:notice] = "Reservation Ended, #{helpers.pluralize(@count, 'accessory')} added"
      if request.xhr?
        render :nothing => true, :status => 200
      else
        redirect_to reservations_path
      end
    else
      render :new, :status => 406, :layout => !request.xhr?
    end
  end

  private

  def ability_resource
    @order_detail
  end

  def authorize_order_detail
    authorize! :add_accessories, @order_detail
  end

  def load_product
    @product = @order_detail.product
  end

  def helpers
    ActionController::Base.helpers
  end
end
