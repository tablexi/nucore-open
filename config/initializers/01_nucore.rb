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
# Log info about how each user is authenticated.
# In the future we may want to record in the DB the means
# by which auth happened.
Warden::Manager.after_authentication do |user,auth,opts|
  Rails.logger.info "User #{user.username} authenticated via #{auth.winning_strategy.class.to_s} at #{user.current_sign_in_at}"
end
