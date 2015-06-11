class TrainingRequestsController < ApplicationController
  admin_tab :index

  before_filter :authenticate_user!
  before_filter :check_acting_as

  layout "two_column"

  def index
    @training_requests = TrainingRequest.for_facility(current_facility)
  end
end
