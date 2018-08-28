# frozen_string_literal: true

module Fullcalendar

  class Engine < Rails::Engine

    require "momentjs-rails"

    initializer "fine_uploader.assets.precompile" do |app|
      app.config.assets.precompile += %w(fullcalendar.js)
    end

  end

end
