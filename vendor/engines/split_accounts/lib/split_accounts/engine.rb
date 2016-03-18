module SplitAccounts
  class Engine < Rails::Engine

    def self.enable!
      # Concat class variables in main rails app
      Account.config.account_types << "SplitAccounts::SplitAccount"
      Account.config.journal_account_types << "SplitAccounts::SplitAccount"

      # Add views to view hooks in main rails app
      ViewHook.add_hook "accounts.show", "after_end_of_form", "split_accounts/shared/show_splits"
      ViewHook.add_hook "facility_accounts.show", "after_end_of_form", "split_accounts/shared/show_splits"

      ::Reports::ExportRaw.transformers << "SplitAccounts::Reports::ExportRawTransformer"
    end

    # This needs to undo everything that enable! does. Used in specs for testing for turning the feature on or off
    def self.disable!
      Account.config.account_types.delete "SplitAccounts::SplitAccount"
      Account.config.journal_account_types.delete "SplitAccounts::SplitAccount"

      ViewHook.remove_hook "accounts.show", "after_end_of_form", "split_accounts/shared/show_splits"
      ViewHook.remove_hook "facility_accounts.show", "after_end_of_form", "split_accounts/shared/show_splits"

      ::Reports::ExportRaw.transformers.delete "SplitAccounts::Reports::ExportRawTransformer"
    end

    config.to_prepare do
      # Include modules in main rails app
      Account.send :include, SplitAccounts::AccountExtension
      FacilityAccountsController.send :include, SplitAccounts::FacilityAccountsControllerExtension

      if SettingsHelper.feature_on?(:split_accounts)
        SplitAccounts::Engine.enable!
      end
    end

    # Include migrations in main rails app
    # https://blog.pivotal.io/labs/labs/leave-your-migrations-in-your-rails-engines
    initializer :append_migrations do |app|
      unless app.root.to_s.match(root.to_s)
        app.config.paths["db/migrate"] += config.paths["db/migrate"].expanded
      end
    end

    # Include factories in main rails app
    initializer "model_core.factories", after: "factory_girl.set_factory_paths" do
      if defined?(FactoryGirl)
        FactoryGirl.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__)
      end
    end

  end
end
