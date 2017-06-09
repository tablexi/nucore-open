require "ldap_authentication/user_extension"
require "ldap_authentication/users_controller_extension"

module LdapAuthentication

  class Engine < Rails::Engine

    config.to_prepare do
      if File.exist?(Rails.root.join("config", "ldap.yml"))
        LdapAuthentication.config = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "ldap.yml"))).result)[Rails.env]
        User.send(:devise, :ldap_authenticatable)
        User.send(:include, LdapAuthentication::UserExtension)
        UsersController.send(:include, LdapAuthentication::UsersControllerExtension)
      end
    end

  end

end

Devise::Models::LdapAuthenticatable.module_eval do
  def password=(new_password)
    super
  end
end
