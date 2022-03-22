# frozen_string_literal: true

require File.expand_path("base", File.dirname(__FILE__))

Daemons::Base.new("recurring_tasks").start do
  RecurringTaskConfig.invoke!

  sleep 1.minute.to_i
end

