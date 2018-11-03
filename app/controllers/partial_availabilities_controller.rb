# frozen_string_literal: true

class PartialAvailabilitiesController < ApplicationController

  admin_tab :all
  layout "two_column"

  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :load_instrument

  def new
    @partial_availability = @instrument.build_partial_availability
  end

  def create
    @partial_availability = @instrument.build_partial_availability(partial_availability_params)

    if @partial_availability.save
      redirect_to facility_instrument_schedule_path(current_facility, @instrument), notice: text("created")
    else
      render action: "new"
    end
  end

  def destroy
    @instrument.partial_availability.destroy
    redirect_to facility_instrument_schedule_path(current_facility, @instrument), notice: text("destroyed")
  end

  private

  def load_instrument
    @instrument = current_facility.instruments.find_by!(url_name: params[:instrument_id])
  end

  def partial_availability_params
    params.require(:partial_availability).permit(:note)
  end

end
