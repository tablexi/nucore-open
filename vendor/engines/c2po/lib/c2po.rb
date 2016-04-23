module C2po

  C2PO_ACCOUNT_TYPES = %w(CreditCardAccount PurchaseOrderAccount).freeze

  class Engine < Rails::Engine

    config.autoload_paths << File.join(File.dirname(__FILE__), "../lib")

    config.to_prepare do
      # Include extensions
      Facility.send :include, C2po::FacilityExtension

      # Concat class variables
      Account.config.account_types.concat C2po::C2PO_ACCOUNT_TYPES
      Account.config.facility_account_types.concat C2po::C2PO_ACCOUNT_TYPES
      Account.config.statement_account_types.concat C2po::C2PO_ACCOUNT_TYPES
      Account.config.affiliate_account_types.concat C2po::C2PO_ACCOUNT_TYPES
      FacilitiesController.permitted_facility_params.concat [:accepts_po, :accepts_cc]

      # Make this engine's views override the main app's views
      paths = ActionController::Base.view_paths.to_a
      index = paths.find_index { |p| p.to_s.include? "c2po" }
      paths.unshift paths.delete_at(index)
      ActionController::Base.view_paths = paths

      # Register view hooks
      ViewHook.add_hook "facilities.manage", "before_is_active", "c2po/facilities/manage"
      ViewHook.add_hook "facilities.facility_fields", "before_is_active", "c2po/facilities/facility_fields"
      ViewHook.add_hook "facility_accounts.show", "after_end_of_form", "c2po/facility_accounts/show/remittance_information"
    end

  end

end
