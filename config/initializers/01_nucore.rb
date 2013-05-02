require 'nucore'
require 'devise_ldap_authenticatable/strategy'


ActiveRecord::Base.class_eval do
  def self.validate_url_name(attr_name)
    validates_length_of attr_name, :in => 3..50
    validates_format_of attr_name, :with => /^[\w-]*$/, :message => "may contain letters, digits, dashes and underscores only"
    validates_uniqueness_of attr_name, :case_sensitive => false
  end
end


#
# We need to augment this module so that it
# A) Will play nicely with database_authenticatable
# B) Will work with User#username
# What you see here is a hack of the original. See
# it for rdoc, etc.
Devise::Strategies::LdapAuthenticatable.class_eval do
  enabled=File.exist?("#{Rails.root}/config/ldap.yml")

  if ENV['RUBY_VERSION'] =~ /ruby-1.9/
    class_variable_set(:@@ldap_enabled, enabled)
  else
    @@ldap_enabled=enabled
  end

  def valid?
    enabled = ENV['RUBY_VERSION'] =~ /ruby-1.9/ ? self.class.class_variable_get(:@@ldap_enabled) : @@ldap_enabled
    enabled && valid_controller? && valid_params? && mapping.to.respond_to?(:authenticate_with_ldap)
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


#
# Log info about how each user is authenticated.
# In the future we may want to record in the DB the means
# by which auth happened.
Warden::Manager.after_authentication do |user,auth,opts|
  Rails.logger.info "User #{user.username} authenticated via #{auth.winning_strategy.class.to_s} at #{user.current_sign_in_at}"
end
