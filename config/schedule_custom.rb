# frozen_string_literal: true

# Add your fork-specific cron jobs here
# This file is automatically included by schedule.rb

# every 20.minutes do
#   rake "something"
# end


every :day, at: "1:30am", roles: [:db] do
  rake "kfs_chart_of_accounts"
end