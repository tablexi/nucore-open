# frozen_string_literal: true

require File.expand_path("base", File.dirname(__FILE__))

Daemons::Base.new("recurring_tasks").start do
  RecurringTaskConfig.recurring_tasks.each do |(worker, method)|
    worker.new.public_send(method)
  end

  sleep 1.minute.to_i
end

