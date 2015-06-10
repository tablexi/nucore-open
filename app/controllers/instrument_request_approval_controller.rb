class InstrumentRequestApprovalController < ApplicationController
  before_filter :load_instrument

  def new; end

  def create
    TrainingRequest.create!(user: current_user, product: @instrument)
    flash[:notice] = I18n.t(
      "controllers.instrument_request_approval.create.notice",
      instrument: @instrument,
    )
    redirect_to facility_path(current_facility)
  end

  private

  def load_instrument
    @instrument = Instrument.find_by_url_name(params[:instrument_id])
  end
end
