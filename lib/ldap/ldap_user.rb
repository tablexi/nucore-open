module Ldap

  class LdapUser

    # Returns an Array of `Ldap::User`s
    def self.search(uid)
      return [] unless uid
      escaped_query = Net::LDAP::Filter.escape(uid)
      ldap_entries = admin_ldap.search(base: admin_ldap.base, filter: "#{Ldap.attribute_field}=#{escaped_query}")
      ldap_entries.map { |entry| new(entry) }
    end

    def self.find(uid)
      search(uid).first
    end

    def self.admin_ldap
      Devise::LDAP::Connection.admin
    end
    private_class_method :admin_ldap

    attr_reader :entry

    def initialize(ldap_entry)
      @ldap_entry = ldap_entry
    end

    def username
      @ldap_entry.public_send(Ldap.attribute_field).last
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
      ::User.new(
        username: username,
        first_name: first_name,
        last_name: last_name,
        email: email,
      )
    end

    def persisted?
      false
    end

  end

end
