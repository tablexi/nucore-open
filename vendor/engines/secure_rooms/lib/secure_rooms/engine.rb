module SecureRooms

  class Engine < ::Rails::Engine

    isolate_namespace SecureRooms

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "SecureRooms::AbilityExtension"
      bundle_index = Product.types.index(Bundle) || -1
      Product.types.insert(bundle_index, SecureRoom)

      ViewHook.add_hook "users.form",
                        "inside_user_form",
                        "secure_rooms/shared/indala_form_field"

      ViewHook.add_hook "users.show",
                        "inside_user_form",
                        "secure_rooms/shared/indala_form_field"
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

  end

end
