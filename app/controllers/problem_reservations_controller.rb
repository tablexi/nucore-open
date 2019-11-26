class ProblemReservationsController < ApplicationController

  customer_tab :all

  before_action :authenticate_user!
  before_action :load_and_authorize_reservation
  before_action { @active_tab = "reservations" }

  def edit
  end

  def update
    raise "Attempting to edit Reservation #{@reservation.id} while not editable" unless editable?

    @order_detail.assign_attributes(
      problem_description_key_was: @order_detail.problem_description_key,
      problem_resolved_at: Time.current,
      problem_resolved_by: current_user,
    )
    @reservation.assign_times_from_params(update_params)

    if @reservation.save
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
    OrderDetails::ProblemResolutionPolicy.new(@order_detail).user_can_resolve?
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
