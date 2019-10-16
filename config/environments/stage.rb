# frozen_string_literal: true

require_relative "production.rb"

Nucore::Application.configure do

  config.action_mailer.delivery_method       = :smtp
  Rails.application.routes.default_url_options = { host: "test.cider.core.uconn.edu", protocol: "https" }
  config.action_mailer.default_url_options   = { host: "test.cider.core.uconn.edu", protocol: "https" }
  config.action_mailer.smtp_settings = {
    address: "smtp.uconn.edu",
    port: 25,
    domain: "test.cider.core.uconn.edu",
  }

end