module Projects

  class Engine < Rails::Engine

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "Projects::AbilityExtension"
      Facility.send :include, Projects::FacilityExtension
      NavTab::LinkCollection.send :include, Projects::LinkCollectionExtension
      ::OrderDetails::ParamUpdater.send :include, Projects::OrderDetails::ParamUpdaterExtension
      OrderDetail.send :include, Projects::OrderDetailExtension
      OrderDetailBatchUpdater.send :include, Projects::OrderDetailBatchUpdaterExtension

      ViewHook.add_hook "order_management.order_details.edit",
                        "after_order_status",
                        "projects/shared/select_project"

      TransactionSearch.searchers[:projects] = Projects::ProjectSearcher
      ViewHook.add_hook "shared.transactions.search",
                        "end_of_first_column",
                        "projects/shared/transactions/search"

      ::Reports::ExportRaw.transformers << "Projects::ExportRawTransformer"

      ViewHook.add_hook "shared.order_detail_action_form",
                        "before_bulk_action_submit_button",
                        "projects/shared/select_facility_project"
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match(root.to_s)
        app.config.paths["db/migrate"] += config.paths["db/migrate"].expanded
      end
    end

    initializer "model_core.factories", after: "factory_girl.set_factory_paths" do
      if defined?(FactoryGirl)
        FactoryGirl.definition_file_paths << File.expand_path("../../../spec/factories", __FILE__)
      end
    end

  end

end
