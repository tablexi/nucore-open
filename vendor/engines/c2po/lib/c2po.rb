# frozen_string_literal: true

module C2po

  ACCOUNT_TYPES = %w(CreditCardAccount PurchaseOrderAccount).freeze

  def self.setup_account_types
    account_types = ACCOUNT_TYPES.dup

    unless SettingsHelper.feature_on?(:credit_card_accounts)
      account_types.delete("CreditCardAccount")
    end

    # Replace C2po account types
    %i(
      account_types
      facility_account_types
      statement_account_types
      affiliate_account_types
    ).each do |config_key|
      Account.config.send(config_key).then do |config_account_types|
        config_account_types.reject! { |type| ACCOUNT_TYPES.include?(type) }
        config_account_types.concat account_types
      end
    end
  end

  class Engine < Rails::Engine

    config.autoload_paths << File.join(File.dirname(__FILE__), "../lib")
    config.eager_load_paths << File.join(File.dirname(__FILE__), "../lib")


    config.to_prepare do
      # Include extensions
      Facility.facility_account_validators << C2po::C2poAccountValidator

      # Permit engine-specific params
      FacilitiesController.permitted_facility_params.push [:accepts_po, :accepts_cc]

      EngineManager.allow_view_overrides!("c2po")

      # Register view hooks
      ViewHook.add_hook "facilities.manage", "before_is_active", "c2po/facilities/manage"
      ViewHook.add_hook "facilities.facility_fields", "before_is_active", "c2po/facilities/facility_fields"
      ViewHook.add_hook "facility_accounts.show", "additional_account_fields", "c2po/facility_accounts/show/additional_account_fields"
      ViewHook.add_hook "facility_accounts.show", "after_end_of_form", "c2po/facility_accounts/show/remittance_information"

      C2po.setup_account_types
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

    initializer :append_account_types, before: "set_routes_reloader_hook" do |app|
      app.reloader.to_run(C2po.method(:setup_account_types))
    end

    initializer "model_core.factories", after: "factory_girl.set_factory_paths" do
      if defined?(FactoryBot)
        FactoryBot.definition_file_paths << File.expand_path("../../spec/factories", __FILE__)
      end
    end

  end

end
