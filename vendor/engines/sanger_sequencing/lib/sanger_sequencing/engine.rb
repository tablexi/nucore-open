module SangerSequencing

  class Engine < ::Rails::Engine

    config.to_prepare do
      NavTab::LinkCollection.send :include, SangerSequencing::LinkCollectionExtension
    end

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match(root.to_s)
        app.config.paths["db/migrate"] += config.paths["db/migrate"].expanded
      end
    end

  end

end
