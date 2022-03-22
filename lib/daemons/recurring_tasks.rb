# frozen_string_literal: true

require File.expand_path("base", File.dirname(__FILE__))

Daemons::Base.new("recurring_tasks").start do
  start_time = Time.now
  RecurringTaskConfig.invoke!
  run_time = Time.now - start_time
  interval = 1.minute.to_i - run_time

  sleep(interval) if interval > 0
end

