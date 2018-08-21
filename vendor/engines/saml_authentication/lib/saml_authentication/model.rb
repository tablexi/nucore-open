# frozen_string_literal: true

# Monkey-patch so we can use `attribute_map` from Settings instead of a file
# There is a PR for something like this, but it's not very pretty and very old.
# https://github.com/apokalipto/devise_saml_authenticatable/pull/65
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
