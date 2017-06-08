module Ldap

  class UserConverter

    def self.from_ldap(ldap_user)
      return unless ldap_user
      new(ldap_user).to_user
    end

    def self.find_and_update_user(user)
      ldap_user = new(Ldap::LdapUser.find(user.username))
      user.update_attributes(ldap_user.attributes)
    end

    def initialize(ldap_user)
      @ldap_user = ldap_user
    end

    def to_user
      ::User.new(attributes)
    end

    def attributes
      [:username, :first_name, :last_name, :email].each_with_object({}) do |field, output|
        output[field] = @ldap_user.public_send(field)
      end
    end

  end

end
