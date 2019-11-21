class ProblemReservationsController < ApplicationController

  customer_tab :all

  before_action :authenticate_user!
  before_action :load_and_authorize_reservation
  before_action { @active_tab = "reservations" }

  def edit
  end

  private

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
