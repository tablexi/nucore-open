module Ldap
  def self.attribute_field
    config['attribute']
  end

  def self.config
    # Taken from devise_ldap_authenticatable / ldap_adapter.rb
    @@config ||= YAML.load(ERB.new(File.read(::Devise.ldap_config || "#{Rails.root}/config/ldap.yml")).result)[Rails.env]
  end
end
