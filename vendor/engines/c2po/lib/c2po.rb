module C2po
  C2PO_ACCOUNT_TYPES = ["CreditCardAccount", "PurchaseOrderAccount"]

  class Engine < Rails::Engine
    config.autoload_paths << File.join(File.dirname(__FILE__), "../lib")

    config.to_prepare do
      # Include extensions
      Facility.send :include, C2po::FacilityExtension
      FacilityAccountsController.send :include, C2po::FacilityAccountsControllerExtension

      # Concat class variables
      Account.config.account_types.concat C2po::C2PO_ACCOUNT_TYPES
      Account.config.facility_account_types.concat C2po::C2PO_ACCOUNT_TYPES
      Account.config.statement_account_types.concat C2po::C2PO_ACCOUNT_TYPES
      Account.config.affiliate_account_types.concat C2po::C2PO_ACCOUNT_TYPES
      FacilityAccountsController.check_billing_access_actions.concat C2po::FacilityAccountsControllerExtension.check_billing_access_actions_extension
      FacilitiesController.permitted_facility_params.concat [:accepts_po, :accepts_cc]

      # Make this engine's views override the main app's views
      paths = ActionController::Base.view_paths.to_a
      index = paths.find_index { |p| p.to_s.include? 'c2po' }
      paths.unshift paths.delete_at(index)
      ActionController::Base.view_paths = paths

      # Register view hooks
      ViewHook.add_hook "facilities.manage", "before_is_active", "c2po/facilities/manage"
      ViewHook.add_hook "facilities.facility_fields", "before_is_active", "c2po/facilities/facility_fields"
      ViewHook.add_hook "admin.shared.sidenav_billing", "after_statements", "c2po/sidenav_billing"
    end

    # make this engine's routes override the main app's routes
    # courtesy of http://stackoverflow.com/a/7040520/162876
    initializer :supersede_routing_paths, :after => :add_routing_paths do |app|
      app_paths = app.routes_reloader.paths
      index = app_paths.find_index { |path| path.include? 'c2po' }
      app_paths.unshift app_paths.delete_at(index)
    end
  end
end
