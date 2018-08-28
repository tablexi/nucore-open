# frozen_string_literal: true

module Admin

  class ServicesController < ApplicationController

    skip_before_action :verify_authenticity_token

    def process_one_minute_tasks
      InstrumentOfflineReservationCanceler.new.cancel!
      AdminReservationExpirer.new.expire!
      head :ok
    end

    def process_five_minute_tasks
      self.class.five_minute_tasks.each do |worker|
        worker.new.perform
      end
      head :ok
    end

    def self.five_minute_tasks
      @five_minute_tasks ||= [AutoExpireReservation, EndReservationOnly, AutoLogout]
    end

  end

end
