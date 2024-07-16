# frozen_string_literal: true

module Projects

  class Engine < Rails::Engine

    config.to_prepare do
      TransactionSearch.register(Projects::ProjectSearcher)
      TransactionSearch.register(Projects::CrossCoreFacilitySearcher, default: false)
    end

  end

end
