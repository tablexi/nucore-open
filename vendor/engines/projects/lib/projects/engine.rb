# frozen_string_literal: true

module Projects

  class Engine < Rails::Engine

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "Projects::AbilityExtension"

      ViewHook.add_hook "reservations.account_field",
                        "after_account",
                        "projects/shared/select_project"

      ViewHook.add_hook "order_management.order_details.form",
                        "after_order_status",
                        "projects/shared/select_project"

      ViewHook.add_hook "order_management.order_details.print_details",
                        "after_account_print",
                        "projects/shared/project"

      ViewHook.add_hook "orders.form",
                        "acting_as",
                        "projects/shared/select_project"

      TransactionSearch.register(Projects::ProjectSearcher)
      TransactionSearch.register(Projects::CrossCoreFacilitySearcher, default: false)

      ViewHook.add_hook "shared.transactions.search",
                        "end_of_first_column",
                        "projects/shared/transactions/search"

      ::Reports::ExportRaw.transformers << "Projects::ExportRawTransformer"

      ViewHook.add_hook "shared.order_detail_action_form",
                        "batch_update_above_product_column",
                        "projects/shared/select_facility_project"
    end

  end

end
