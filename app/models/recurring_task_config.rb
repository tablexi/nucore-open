# frozen_string_literal: true

class RecurringTaskConfig

  # Returns an array of recurring task classes and their calling methods.
  # Engines can append to this list.
  def self.recurring_tasks
    @@recurring_tasks ||= [
      [AutoExpireReservation, :perform],
      [EndReservationOnly, :perform],
      [AutoLogout, :perform],
      [InstrumentOfflineReservationCanceler, :cancel!],
      [AdminReservationExpirer, :expire!],
      [AutoCanceler, :cancel_reservations],
    ]
  end

end
