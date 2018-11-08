# frozen_string_literal: true

module LdapAuthentication

  class UserEntry

    # Returns an Array of `LdapAuthentication::UserEntry`s
    def self.search(uid)
      return [] unless uid

      ldap_entries = nil
      ActiveSupport::Notifications.instrument "search.ldap_authentication" do |payload|
        ldap_entries = admin_ldap.search(filter: Net::LDAP::Filter.eq(LdapAuthentication.attribute_field, uid))
        payload[:uid] = uid
        payload[:results] = ldap_entries
      end

      ldap_entries.map { |entry| new(entry) }
    end

    # Returns a single LdapAuthentication::UserEntry
    def self.find(uid)
      search(uid).first
    end

    def self.admin_ldap
      LdapAuthentication.admin_connection
    end
    private_class_method :admin_ldap

    def initialize(ldap_entry)
      @ldap_entry = ldap_entry
    end

    def username
      @ldap_entry.public_send(LdapAuthentication.attribute_field).last
    end

    def first_name
      @ldap_entry.givenname.first
    end

    def last_name
      @ldap_entry.sn.first
    end

    def email
      @ldap_entry.mail.first
    end

    def to_user
      UserConverter.new(self).to_user
    end

  end

end
