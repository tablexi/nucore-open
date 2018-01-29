# Monkey-patch so we can use `attribute_map` from Settings instead of a file
module Devise

  module Models

    module SamlAuthenticatable

      module ClassMethods

        def attribute_map
          Settings.saml.attribute_map.to_h.stringify_keys
        end

      end

    end

  end

end
