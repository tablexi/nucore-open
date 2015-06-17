class TrainingRequestsController < ApplicationController
  admin_tab :index

  before_filter :authenticate_user!
  before_filter :check_acting_as

  load_and_authorize_resource except: :index

  layout "two_column"

  def new
    @instrument = Instrument.new
  end

  def create
    load_instrument
    if TrainingRequest.create(user: current_user, product: @instrument)
      flash[:notice] = t("training_requests.create.success", product: @instrument)
    else
      flash[:error] = t("training_requests.create.failure", product: @instrument)
    end
    redirect_to facility_path(current_facility)
  end

  def index
    @training_requests = current_facility.training_requests
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

  def load_instrument
    @instrument = Instrument.find_by_url_name!(params[:instrument_id])
  end
end
