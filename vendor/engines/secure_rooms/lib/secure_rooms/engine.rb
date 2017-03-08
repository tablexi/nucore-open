module SecureRooms

  class Engine < ::Rails::Engine

    isolate_namespace SecureRooms

    config.to_prepare do
      bundle_index = Product.types.index(Bundle) || -1
      Product.types.insert(bundle_index, SecureRoom)

      ViewHook.add_hook "users.show",
                        "additional_user_fields",
                        "secure_rooms/shared/card_number_form_field"
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
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
