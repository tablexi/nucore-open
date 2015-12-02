module SplitAccounts
  class Engine < Rails::Engine

    # Include modules in main rails app
    config.to_prepare do
      Account.send :include, SplitAccounts::AccountExtensions
    end

    # Include migrations in main rails app
    # https://blog.pivotal.io/labs/labs/leave-your-migrations-in-your-rails-engines
    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        app.config.paths["db/migrate"] += config.paths["db/migrate"].expanded
      end
    end

    # Include factories in main rails app
    initializer "model_core.factories", after: "factory_girl.set_factory_paths" do
      FactoryGirl.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryGirl)
    end

  end
end
