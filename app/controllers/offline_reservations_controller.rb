class OfflineReservationsController < ApplicationController

  admin_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :load_instrument

  load_and_authorize_resource class: Reservation

  def new
    @reservation = @instrument.offline_reservations.new

    render layout: "two_column"
  end

  def create
    @reservation = @instrument.offline_reservations.new(params[:reservation])
    @reservation.reserve_start_at = Time.current

    if @reservation.save
      flash[:notice] = text("create.success")
      redirect_to facility_instrument_schedule_path
    else
      render action: "new", layout: "two_column"
    end
  end

  private

  def load_instrument
    @instrument = current_facility.instruments.find_by!(url_name: params[:instrument_id])
  end

end
