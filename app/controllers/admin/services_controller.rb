module Admin

  class ServicesController < ApplicationController

    def cancel_reservations_for_offline_instruments
      InstrumentOfflineReservationCanceler.new.cancel!
      render nothing: true
    end

  end

end
