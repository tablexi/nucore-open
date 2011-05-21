namespace :db do
  
  desc "Drop database for current RAILS_ENV"
  task :oracle_drop => :environment do
    config= Rails.configuration.database_configuration[Rails.env]
    connect_string = "#{config["username"]}/#{config["password"]}@#{config["database"]}"
    system "bash -ic 'cd #{Rails.root}/db && ./generate_drops.sh | sqlplus #{connect_string}'"
  end

  desc "Drop current database and rebuild from schema"
  task :oracle_reset => [:environment, :oracle_drop, :reset] do
    
  end

  desc "Drop current database, rebuild from schema, seed with bi_seed"
  task :oracle_bi_reset => [:environment, :oracle_reset, :bi_seed] do
    
  end

  desc "Drop current database, rebuild from schema, seed with demo_seed "
  task :oracle_demo_reset => [:environment, :oracle_reset, :demo_seed] do
    
  end
end