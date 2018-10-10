namespace :ldap_authentication do


  # task :user_status, [:username] => :environment do |_t, args|
  #   entry = LdapAuthentication::UserEntry.find(args[:username])
  # end

  desc "Check status of LDAP users"
  task user_status: :environment do
    User.authenticated_externally.find_each do |user|
      entry = LdapAuthentication::UserEntry.find(user.username)
      puts "#{user.username} : #{entry ? 'active' : 'inactive'}"
    end
  end

  desc "Disable users removed from LDAP directory"
  task disable_removed_users: :environment do
    User.authenticated_externally.active.find_each do |user|
      entry = LdapAuthentication::UserEntry.find(user.username)
      if entry.blank?
        puts "Suspending #{user.username}"
        user.update!(suspended_at: Time.current)
      end
    end
  end
end
