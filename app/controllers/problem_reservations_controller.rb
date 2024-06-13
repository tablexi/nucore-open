# frozen_string_literal: true

class ProblemReservationsController < ApplicationController

  customer_tab :all

  before_action :authenticate_user!
  before_action :load_and_authorize_reservation
  before_action :prevent_double_update, only: :update
  before_action { @active_tab = "reservations" }

  layout -> { modal? ? false : "application" }

  delegate :editable?, :resolved?, to: :problem_reservation_resolver

  def edit
    if !editable? && resolved?
      render :resolved
    elsif modal?
      @redirect_to_order_id = params[:redirect_to_order_id]
      render layout: false
    end
  end

  def update
    @redirect_to_order_id = params[:redirect_to_order_id]

    if problem_reservation_resolver.resolve(update_params.merge(current_user:))
      redirect_to redirect_to_path, notice: text("update.success")
    elsif modal?
      render :edit, layout: false
    else
      render :edit
    end
  end

  private

  def prevent_double_update
    redirect_to order_order_detail_path(@order_detail.order, @order_detail) unless editable?
  end

  def update_params
    params.require(:reservation).permit(
      :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian, :actual_duration_mins
    )
  end

  def problem_reservation_resolver
    @problem_reservation_resolver ||= ProblemReservationResolver.new(@reservation)
  end

  def load_and_authorize_reservation
    @reservation = if SettingsHelper.feature_on?(:cross_core_projects) && params[:redirect_to_order_id].present?
                     Reservation.find(params[:id])
                   else
                     current_user.reservations.find(params[:id])
                   end

    @order_detail = @reservation.order_detail

    raise ActiveRecord::RecordNotFound unless editable? || resolved?
    authorize! :update, @reservation
  end

  def ability_resource
    @reservation
  end

  def redirect_to_path
    redirect_to_order_id = params[:redirect_to_order_id]

    if modal? && redirect_to_order_id.present?
      order = Order.find(redirect_to_order_id)

      return facility_order_path(@facility, order.id) if order.present?
    end

    if @order_detail.accessories?
      new_order_order_detail_accessory_path(@order_detail.order, @order_detail)
    else
      reservations_status_path(status: "all")
    end
  end

  def modal?
    request.xhr?
  end
  helper_method :modal?

end
