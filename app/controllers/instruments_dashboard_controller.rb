class InstrumentsDashboardController < ApplicationController

  layout "plain"

  def index
    @instruments = current_facility.instruments
    if url_for == request.referer # Is it a refresh?
      render partial: "dashboard", locals: { instruments: @instruments }
    end
  end

end
