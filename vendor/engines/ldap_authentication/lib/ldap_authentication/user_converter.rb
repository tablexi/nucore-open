module LdapAuthentication

  class UserConverter

    CONVERTABLE_ATTRIBUTES = [:username, :first_name, :last_name, :email].freeze

    def initialize(ldap_user)
      @ldap_user = ldap_user
    end

    def to_user
      ::User.new(attributes)
    end

    def attributes
      CONVERTABLE_ATTRIBUTES.each_with_object({}) do |field, output|
        output[field] = @ldap_user.public_send(field)
      end
    end

  end

end
