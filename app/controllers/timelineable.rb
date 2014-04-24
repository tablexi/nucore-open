module Timelineable
  def timeline
    @display_date = parse_usa_date(params[:date]) if params[:date]
    @display_date ||= Time.zone.now

    @schedules = current_facility.schedules.active.order(:name)
    # @instruments = current_facility.instruments.active_plus_hidden.order(:name)
  end
end
