namespace :cleanup  do
  namespace :accounts do

    desc "clean up accounts.expires_at column"
    task :expires_at => :environment do

      Account.all.each do |a|
        AccountCleaner.clean_expires_at(a)
      end

    end

  end

end
