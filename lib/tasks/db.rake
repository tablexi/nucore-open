namespace :db do

  desc "Drop database for current RAILS_ENV"
  task :oracle_drop => :environment do
    config= Rails.configuration.database_configuration[Rails.env]
    connect_string = "#{config["username"]}/#{config["password"]}@#{config["database"]}"
    system "bash -ic 'cd #{Rails.root}/db && ./generate_drops.sh | sqlplus #{connect_string}'"
  end

end
