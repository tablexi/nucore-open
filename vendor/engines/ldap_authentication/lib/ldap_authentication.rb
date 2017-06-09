require "devise_ldap_authenticatable"
require "ldap_authentication/user_entry"
require "ldap_authentication/user_converter"
require "ldap_authentication/engine"

module LdapAuthentication

  def self.config
    return { "attribute" => "uid" } if Rails.env.test?

    if File.exist?(Rails.root.join("config", "ldap.yml"))
      @config ||= YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "ldap.yml"))).result)[Rails.env]
    end
  end

  def self.attribute_field
    config["attribute"]
  end

end
