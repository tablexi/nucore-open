module Admin

  class ServicesController < ApplicationController

    skip_before_action :verify_authenticity_token

    def process_one_minute_tasks
      InstrumentOfflineReservationCanceler.new.cancel!
      AdminReservationExpirer.new.expire!
      render nothing: true
    end

    def process_five_minute_tasks
      self.class.five_minute_tasks.each do |worker|
        worker.new.perform
      end
      render nothing: true
    end

    def self.five_minute_tasks
      @five_minute_tasks ||= [AutoExpireReservation, EndReservationOnly, AutoLogout]
    end

  end

end
