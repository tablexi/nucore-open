# frozen_string_literal: true

module NuResearchSafety

  class Engine < ::Rails::Engine

    config.to_prepare do
      OrderPurchaseValidator.additional_validations << NuResearchSafety::OrderCertificateValidator

      if EngineManager.engine_loaded?("SecureRooms")
        # This is in the lib path so it is not eager loaded
        require "nu_research_safety/secure_room_access_rule"
        ArrayUtil.insert_before(
          SecureRooms::CheckAccess.rules,
          NuResearchSafety::SecureRoomAccessRule,
          SecureRooms::AccessRules::AccountSelectionRule,
        )
      end
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

    initializer "model_core.factories", after: "factory_girl.set_factory_paths" do
      if defined?(FactoryBot)
        FactoryBot.definition_file_paths << File.expand_path("../../../spec/factories", __FILE__)
      end
    end

  end

end
