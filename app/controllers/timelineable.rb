module Timelineable
  extend ActiveSupport::Concern

  included do
    helper TimelineHelper
  end

  def timeline
    @display_date = parse_usa_date(params[:date]) if params[:date]
    @display_date ||= Time.zone.now

    @schedules = current_facility.schedules.active.order(:name)
  end
end
