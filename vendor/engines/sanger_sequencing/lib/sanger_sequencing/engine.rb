module SangerSequencing

  class Engine < ::Rails::Engine

    isolate_namespace SangerSequencing

    config.generators do |g|
      g.test_framework :rspec
    end

  end

end
