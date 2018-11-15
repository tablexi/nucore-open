# frozen_string_literal: true

namespace :ldap_authentication do
  desc "Check status of LDAP users"
  task user_status: :environment do
    User.authenticated_externally.unexpired.find_each do |user|
      entry = LdapAuthentication::UserEntry.find(user.username)

      puts [
        entry.present? ? "active" : "inactive",
        user.username,
        user.email,
        user.first_name,
        user.last_name,
        user.created_at&.iso8601,
        user.last_sign_in_at&.iso8601,
        user.suspended_at&.iso8601,
      ].join("\t")
    end
  end

  desc "Expire users removed from LDAP directory"
  task expire_removed_users: :environment do
    User.authenticated_externally.unexpired.find_each do |user|
      entry = LdapAuthentication::UserEntry.find(user.username)
      if entry.blank?
        puts "Expiring #{user.username}"
        user.update!(expired_at: Time.current, expired_note: "No longer in LDAP directory")
      end
    end
  end
end
