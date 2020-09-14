# frozen_string_literal: true

class InstrumentSchedulePositionsController < ApplicationController

  layout "two_column"

  admin_tab :all
  before_action :authenticate_user!
  before_action :init_current_facility
  before_action :authorize_schedules, except: [:show]
  before_action :load_schedules

  # GET /facilities/:facility_id/instrument_schedule_position
  def show
    authorize! :read, Schedule
  end

  # GET /facilities/:facility_id/instrument_schedule_position/edit
  def edit
  end

  # PUT/PATCH /facilities/:facility_id/instrument_schedule_position
  def update
    Schdeule.transaction do
      @schedules.each do |schedule|
        position = params[:instrument_schedule_position][:schedule_ids].index(schedule.id.to_s)
        schedule.update!(position: position)
      end
    end
    redirect_to facility_instrument_schedule_position_path, notice: text("success")
  end

  private

  def update_params
    params.require(:instrument_schedule_position).permit(schedule_ids: [])
  end

  def authorize_schedules
    authorize! :edit, Schedule
  end

  def load_schedules
    @schedules = Schedule
                 .order_by_asc_nulls_last(:position)
                 .order(:name)
                 .joins(facility: :instruments)
                 .merge(
                    Instrument
                    .active
                    .in_active_facility
                    .for_facility(current_facility)
                 )
                 .distinct
  end

end
