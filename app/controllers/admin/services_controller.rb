module Admin

  class ServicesController < ApplicationController

    skip_before_action :verify_authenticity_token, only: :cancel_reservations_for_offline_instruments

    def cancel_reservations_for_offline_instruments
      InstrumentOfflineReservationCanceler.new.cancel!
      render nothing: true
    end

    def process_five_minute_tasks
      workers = [AutoExpireReservation, EndReservationOnly, AutoLogout]

      workers.each do |worker|
        worker.new.perform
      end

      render nothing: true
    end

  end

end
