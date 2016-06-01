module SangerSequencing

  class Engine < ::Rails::Engine

    config.to_prepare do
      NavTab::LinkCollection.send :include, SangerSequencing::LinkCollectionExtension
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

  end

end
