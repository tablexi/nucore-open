namespace :ldap_authentication do

  desc "Check status of LDAP users"
  task user_status: :environment do
    User.authenticated_externally.find_each do |user|
      entry = LdapAuthentication::UserEntry.find(user.username)
      puts "#{user.username} : #{entry ? 'active' : 'inactive'}"
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
