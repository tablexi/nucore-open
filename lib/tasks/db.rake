namespace :db do
  def db_allow_task?
    if Rails.env.test? || Rails.env.development?
      true
    else
      puts "Only allowed in development and test mode"
      false
    end
  end

  desc "Drop database for current RAILS_ENV"
  task :oracle_drop => :environment do
    next unless db_allow_task?
    config= Rails.configuration.database_configuration[Rails.env]
    connect_string = "#{config["username"]}/#{config["password"]}@#{config["database"]}"
    system "bash -ic 'cd #{Rails.root}/db && ./generate_drops.sh | sqlplus #{connect_string}'"
  end

  desc "DANGER! Drops all user tables and sequences"
  task :oracle_drop_severe => :environment do
    next unless db_allow_task?

    table_names = ActiveRecord::Base.connection.select_rows(
      "select table_name from user_tables").map(&:first)
    table_names.each do |table|
      begin
        command = "drop table #{table} cascade constraints purge"
        puts command
        ActiveRecord::Base.connection.execute(command)
      rescue => e
        puts e.message
      end
    end

    sequence_names = ActiveRecord::Base.connection.select_rows(
      "select sequence_name from user_sequences").map(&:first)

    sequence_names.each do |sequence|
      begin
        seq_command = "drop sequence #{sequence}"
        puts seq_command
        ActiveRecord::Base.connection.execute(seq_command)
      rescue => e
        puts e.message
      end
    end
  end

end
