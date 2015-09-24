# IMPORTANT!!! You should never edit this file in your custom fork.
# If you want to add custom jobs to your instance, add them to schedule_custom.rb

# Override the default :rake option excluding the `--silent` option so output is
# still sent via email to sysadmins
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task :output"

every 5.minutes do
  rake "order_details:expire_reservations"
end

every 5.minutes do
  rake "order_details:auto_logout"
end

every :day, at: '4:17am' do
  rake "order_details:remove_merge_orders"
end

require "active_support/core_ext/numeric/time"
instance_eval(File.read(File.expand_path("../schedule_custom.rb", __FILE__)), 'schedule_custom.rb')

# Learn more: http://github.com/javan/whenever
