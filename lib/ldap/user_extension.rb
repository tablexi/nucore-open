module Ldap

  module UserExtension

    extend ActiveSupport::Concern

    included do
      devise :ldap_authenticatable
    end

    module ClassMethods

      def find_for_ldap_authentication(attributes = {})
        resource = super
        resource unless resource.authenticated_locally?
      end

    end

  end

end
