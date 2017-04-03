module SecureRooms

  class Engine < ::Rails::Engine

    isolate_namespace SecureRooms

    config.to_prepare do
      ::AbilityExtensionManager.extensions << "SecureRooms::AbilityExtension"

      bundle_index = Product.types.index(Bundle) || -1
      Product.types.insert(bundle_index, SecureRoom)

      ViewHook.add_hook "users.show",
                        "additional_user_fields",
                        "secure_rooms/shared/card_number_form_field"

      ViewHook.add_hook "admin.shared.tabnav_product",
                        "additional_tabs",
                        "secure_rooms/shared/tabnav_secure_room"

      ViewHook.add_hook "admin.shared.tabnav_users",
                        "after",
                        "secure_rooms/shared/tabnav_users"
    end

    initializer "secure_rooms.action_controller" do
      ActiveSupport.on_load :action_controller do
        helper SecureRooms::SecureRoomsHelper
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
