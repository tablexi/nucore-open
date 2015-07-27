module Timelineable
  extend ActiveSupport::Concern

  included do
    helper TimelineHelper
  end

  def timeline
    @display_date = display_date_as_time.to_date
    @schedules = current_facility.schedules.active.order(:name)
  end

  private

  def display_date_as_time
    (parse_usa_date(params[:date]) if params[:date]) || Time.zone.now
  end
end
