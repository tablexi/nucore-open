require "devise_ldap_authenticatable"
require "ldap_authentication/user_entry"
require "ldap_authentication/user_converter"
require "ldap_authentication/null_connection"
require "ldap_authentication/engine"

module LdapAuthentication

  def self.configure!
    @config = config
  end

  def self.config
    if File.exist?(Rails.root.join("config", "ldap.yml"))
      yaml = YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "ldap.yml"))).result) || {}
      config = yaml.fetch(Rails.env, {})

      if Rails.env.test?
        @admin_connection = NullConnection.new
      elsif config.blank?
        raise "Error configuring LDAP. Check your config/ldap.yml file."
      end

      config
    end
  end

  def self.admin_connection
    @admin_connection ||= Devise::LDAP::Connection.admin
  end

  def self.attribute_field
    config.fetch("attribute", "uid")
  end

end
