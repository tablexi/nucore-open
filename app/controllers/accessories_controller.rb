class AccessoriesController < ApplicationController
  load_resource :order
  load_resource :order_detail, :through => :order

  before_filter :authorize_order_detail
  before_filter :load_product

  def new
    accessorizer = Accessories::Accessorizer.new(@order_detail)
    # If being done by a facility admin, only show the accessories that haven't already been
    # added. To update accessories already added, they should use the normal order view.
    @order_details = current_facility ? accessorizer.unpurchased_accessory_order_details : accessorizer.accessory_order_details
    render :layout => false if request.xhr?
  end

  def create
    accessorizer = Accessories::Accessorizer.new(@order_detail)

    update_response = if current_facility
      accessorizer.update_unpurchased_attributes(params[:accessories])
    else
      accessorizer.update_attributes(params[:accessories])
    end

    @order_details = update_response.order_details

    if update_response.valid?
      flash[:notice] = t("controllers.accessories.create.success", accessories: helpers.pluralize(update_response.persisted_count, 'accessory'))
      respond_success
    else
      render :new, :status => 406, :layout => !request.xhr?
    end
  end

  private

  def respond_success
    if request.xhr?
      render :nothing => true, :status => 200
    else
      redirect_to current_facility ? [current_facility, @order] : reservations_path
    end
  end

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
