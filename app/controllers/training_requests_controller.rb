class TrainingRequestsController < ApplicationController
  admin_tab :index

  before_filter :authenticate_user!
  before_filter :check_acting_as

  load_and_authorize_resource except: :index

  layout "two_column"

  def index
    @training_requests = TrainingRequest.for_facility(current_facility)
  end

  def destroy
    if @training_request.destroy
      flash[:notice] = t("training_requests.destroy.success", flash_arguments)
    else
      flash[:error] = t("training_requests.destroy.failure", flash_arguments)
    end
    redirect_to facility_training_requests_path(current_facility)
  end

  private

  def flash_arguments
    @flash_arguments ||= {
      user: @training_request.user.to_s,
      product: @training_request.product.to_s,
    }
  end
end
