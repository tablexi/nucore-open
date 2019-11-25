class ProblemReservationsController < ApplicationController

  customer_tab :all

  before_action :authenticate_user!
  before_action :load_and_authorize_reservation
  before_action { @active_tab = "reservations" }

  def edit
  end

  def update
    form = ProblemReservationForm.new(@reservation)
    form.assign_attributes(update_params)
    if form.save
      redirect_to reservations_status_path(status: "all"), notice: "Your reservation has been updated"
    else
      render :edit
    end
  end

  private

  def update_params
    params.require(:reservation).permit(
      :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian, :actual_duration_mins
    )
  end

  def editable?
    @order_detail.problem? && @order_detail.problem_description_key == :missing_actuals
  end
  helper_method :editable?

  def load_and_authorize_reservation
    @reservation = Reservation.find(params[:id])
    @order_detail = @reservation.order_detail
    authorize! :update, @reservation
  end

  def ability_resource
    @reservation
  end
end
