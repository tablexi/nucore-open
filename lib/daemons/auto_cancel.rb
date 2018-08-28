# frozen_string_literal: true

require File.expand_path("base", File.dirname(__FILE__))

Daemons::Base.new("auto_cancel").start do
  canceler = AutoCanceler.new
  canceler.cancel_reservations

  sleep 1.minute.to_i
end
