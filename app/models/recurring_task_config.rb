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

  def self.invoke!
    recurring_tasks.each do |task_params|
      RecurringTask.new(task_params).invoke!
    end
  end

  RecurringTask = Struct.new(:task_class, :call_method) do
    def invoke!
      task_class.new.public_send(call_method)
    end
  end
end
