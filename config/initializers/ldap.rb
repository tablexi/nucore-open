Rails.application.config.to_prepare do
  if File.exist?("#{Rails.root}/config/ldap.yml")
    User.send(:devise, :ldap_authenticatable)
    UsersController.send(:include, Ldap::UsersControllerExtension)
  end
end

#
# We don't set passwords via LDAP. If setting a password
# defer to the next strategy (encryptable or database_authenticatable)
Devise::Models::LdapAuthenticatable.module_eval do
  def password=(new_password)
    super
  end
end
