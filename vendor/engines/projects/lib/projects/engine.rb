# frozen_string_literal: true

module Projects

  class Engine < Rails::Engine

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "Projects::AbilityExtension"

      TransactionSearch.register(Projects::ProjectSearcher)
      TransactionSearch.register(Projects::CrossCoreFacilitySearcher, default: false)

      ::Reports::ExportRaw.transformers << "Projects::ExportRawTransformer"
    end

  end

end
