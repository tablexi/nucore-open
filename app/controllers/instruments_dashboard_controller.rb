class InstrumentsDashboardController < ApplicationController

  layout "plain"

  def index
    @reservations = current_facility.reservations.current_in_use.merge(Product.alphabetized)
    if params[:refresh]
      render partial: "dashboard", locals: { reservations: @reservations }
    end
  end

end
