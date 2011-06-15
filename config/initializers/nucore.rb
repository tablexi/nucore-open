require 'nucore'


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
Devise::Models::LdapAuthenticatable.module_eval do
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      # don't overwrite DatabaseAuthenticatable's #password accessors
    end
  end

  module ClassMethods
    def authenticate_with_ldap(attributes={})
      auth_key=Devise.authentication_keys[0]
      # We use #username, not #login. The ldap_authenticatable gem should do this for us, and does in the Rails 3 version
      return unless Devise.ldap_host and attributes[auth_key].present?
      conditions = attributes.slice(auth_key)

      unless conditions[auth_key]
        conditions[auth_key] = "#{conditions[auth_key]}"
      end

      resource = find_for_ldap_authentication(conditions)
      resource = new(conditions) if (resource.nil? and ::Devise.ldap_create_user)

      if resource.try(:valid_ldap_authentication?, attributes[:password])
         resource.new_record? ? create(conditions) : resource
      end
    end


    protected

    # we don't change this, but need to include it to make it available to #authenticate_with_ldap
    def find_for_ldap_authentication(conditions)
      find(:first, :conditions => conditions)
    end
  end
end


#
# Password-less users are externally authenticated users.
# Don't let DatabaseAuthenticatable require passwords for all users.
Devise::Models::DatabaseAuthenticatable.module_eval do
  protected

  def password_required?
    return false
  end
end


#
# Log info about how each user is authenticated.
# In the future we may want to record in the DB the means
# by which auth happened.
Warden::Manager.after_authentication do |user,auth,opts|
  Rails.logger.info "User #{user.username} authenticated via #{auth.winning_strategy.class.to_s} at #{user.current_sign_in_at}"
end
