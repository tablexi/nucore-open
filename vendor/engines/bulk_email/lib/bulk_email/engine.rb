module BulkEmail

  class Engine < Rails::Engine

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "BulkEmail::AbilityExtension"
      ViewHook.add_hook "admin.shared.sidenav_users", "after_facility_users", "bulk_email/admin/bulk_email_tab"
      ViewHook.add_hook "instruments.schedule", "after_offline_toggle", "bulk_email/instruments/send_mail_button"
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

    initializer "model_core.factories", after: "factory_girl.set_factory_paths" do
      if defined?(FactoryGirl)
        FactoryGirl.definition_file_paths << File.expand_path("../../../spec/factories", __FILE__)
      end
    end

  end

end
