# frozen_string_literal: true

module Timelineable

  extend ActiveSupport::Concern

  included do
    helper TimelineHelper
  end

  def timeline
    @display_datetime = display_date_as_time
    @schedules = current_facility.schedules.active.order(:name)
  end

  private

  def display_date_as_time
    parse_usa_date(params[:date]) || Time.current.beginning_of_day
  end

end
