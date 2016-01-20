class TrainingRequestsController < ApplicationController
  admin_tab :index

  before_filter :authenticate_user!
  before_filter :check_acting_as

  load_and_authorize_resource

  # GET /facilities/:facility_id/products/:product_id/training_requests/new
  def new
    load_product
  end

  # POST /facilities/:facility_id/products/:product_id/training_requests
  def create
    load_product
    @training_request = TrainingRequest.new(user: current_user, product: @product)
    if @training_request.save
      trigger_email_to_facility_staff
      flash[:notice] = t("training_requests.create.success", product: @product)
    else
      flash[:error] = t("training_requests.create.failure", product: @product)
    end
    redirect_to facility_path(current_facility)
  end

  # GET /facilities/:facility_id/training_requests
  def index
    @training_requests = current_facility.training_requests

    render layout: "two_column"
  end

  # DELETE /facilities/:facility_id/training_requests/:id
  def destroy
    if @training_request.destroy
      flash[:notice] = t("training_requests.destroy.success", flash_arguments)
    else
      flash[:error] = t("training_requests.destroy.failure", flash_arguments)
    end
    redirect_to facility_training_requests_path(current_facility)
  end

  private

  def trigger_email_to_facility_staff
    TrainingRequestMailer.delay.notify_facility_staff(current_user.id, @product.id)
  end

  def flash_arguments
    @flash_arguments ||= {
      user: @training_request.user.to_s,
      product: @training_request.product.to_s,
    }
  end

  def load_product
    @product =
      current_facility.products.active.find_by_url_name!(params[:product_id])
  end
end
