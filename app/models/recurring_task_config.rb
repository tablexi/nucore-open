# frozen_string_literal: true

class RecurringTaskConfig

  # Returns an array of recurring task classes, their calling methods,
  # and how often (in minutes) to run the task.
  # Engines can append to this list.
  def self.recurring_tasks
    @@recurring_tasks ||= [
      [[AutoExpireReservation, :perform], 5],
      [[EndReservationOnly, :perform], 5],
      [[AutoLogout, :perform], 5],
      [[InstrumentOfflineReservationCanceler, :cancel!], 1],
      [[AdminReservationExpirer, :expire!], 1],
      [[AutoCanceler, :cancel_reservations], 1],
    ]
  end

  def self.invoke!
    start_time = Time.now
    recurring_tasks.each do |(task_params, frequency)|
      if start_time.min % frequency == 0
        RecurringTask.new(task_params).invoke!
      end
    end
  end

  RecurringTask = Struct.new(:task_class, :call_method) do
    def invoke!
      task_class.new.public_send(call_method)
    end
  end

end
