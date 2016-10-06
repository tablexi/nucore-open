module BulkEmail

  class Engine < Rails::Engine

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "BulkEmail::AbilityExtension"
      ViewHook.add_hook "admin.shared.sidenav_users", "after_facility_users", "bulk_email/admin/bulk_email_tab"
      ViewHook.add_hook "instruments.schedule", "after_offline_toggle", "bulk_email/instruments/send_mail_button"
    end

  end

end
