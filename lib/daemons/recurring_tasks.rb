# frozen_string_literal: true

require File.expand_path("base", File.dirname(__FILE__))

Daemons::Base.new("recurring_tasks").start do
  # Only run on 1 instance.
  # TODO: This should probably be an ENV variable instead
  if Rails.application.secrets.run_recurring_tasks
    tasks ||=
      [
        [AutoExpireReservation, :perform],
        [EndReservationOnly, :perform],
        [AutoLogout, :perform],
        [InstrumentOfflineReservationCanceler, :cancel!],
        [AdminReservationExpirer, :expire!],
        [AutoCanceler, :cancel_reservations],
      ]
    tasks.each do |(worker, method)|
      worker.new.public_send(method)
    end
  end

  sleep 1.minute.to_i
end

