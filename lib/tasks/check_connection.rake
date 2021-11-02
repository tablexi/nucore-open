# frozen_string_literal: true

# Every 1 and 5 minutes the system sends itself a curl command.
# If curl commands from the server to itself are failing, we want to know.
# See config/schedule.rb
desc "confirm HTTP calls are getting through to the server"
task check_connection: :environment do
  root_url = Rails.application.routes.url_helpers.root_url
  uri = URI(root_url)
  begin
    response = Net::HTTP.get_response(uri)
  rescue => e
    if defined?(Rollbar)
      Rollbar.error("Connection check failed, are the 1 and 5 minute tasks running?", message: e.message)
    else
      Rails.logger.error("Connection check failed, are the 1 and 5 minute tasks running?", message: e.message)
    end
  end
end
