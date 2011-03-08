namespace :nucs do

  desc "Reads a CSV file of chart strings and reports those that are invalid.\n
        Expects headers fund,department,project,activity,account,amount in the file"
  task :validate_chart_strings, [:path_to_csv] => :environment do |t, args|
    require 'faster_csv'

    good, bad=0, 0

    FasterCSV.foreach(args.path_to_csv, :headers => true) do |row|
      chart_string=[ 'fund', 'department', 'project', 'activity' ].collect! {|c| row[c] }
      chart_string=(chart_string.delete_if {|c| c.blank?}).join('-')

      begin
        NucsValidator.new(chart_string, row['account']).account_is_open!
      rescue NucsErrors::NucsError => e
        puts "#{row['amount'].to_i < 0 ? 'recharge' : ''} account #{row['account']} not open for #{chart_string}: #{e.message}"
        bad += 1
      else
        good += 1
      end
    end

    puts ">>> Checked #{good+bad} chart strings, found #{good} good ones and #{bad} bad ones <<<"
  end

  namespace :import do

    desc "Imports all GE001, GL066, and Grants Budget Tree data"
    task :all, [:path_to_files_dir] => :environment do |t, args|
      dir=args.path_to_files_dir
      Rake::Task['nucs:import:GL066'].invoke(File.join(dir, 'GL066-BudgetedChartStrings.txt'))
      Rake::Task['nucs:import:grants_budget_tree'].invoke(File.join(dir, 'GrantsBudgetTree.txt'))
      Rake::Task['nucs:import:GE001:funds'].invoke(File.join(dir, 'GE001-#1Fund.txt'))
      Rake::Task['nucs:import:GE001:departments'].invoke(File.join(dir, 'GE001-#2Dept.txt'))
      Rake::Task['nucs:import:GE001:projects_activities'].invoke(File.join(dir, 'GE001-#3ProjectActivity.txt'))
      Rake::Task['nucs:import:GE001:programs'].invoke(File.join(dir, 'GE001-#4Program.txt'))
      Rake::Task['nucs:import:GE001:accounts'].invoke(File.join(dir, 'GE001-#5Account.txt'))
      Rake::Task['nucs:import:GE001:chart_field1s'].invoke(File.join(dir, 'GE001-#6ChartField1.txt'))
    end


    desc "Reads a file of valid GL066 chart strings and stores them in the DB"
    task :GL066, [:path_to_file] => :environment do |t, args|
      NucsGl066.source(args.path_to_file)
    end


    desc "Reads a file of valid grants budget trees and stores them in the DB"
    task :grants_budget_tree, [:path_to_file] => :environment do |t, args|
      NucsGrantsBudgetTree.source(args.path_to_file)
    end

    
    namespace :GE001 do

      desc "Reads a file of valid GEOO1 chart string fund components and stores them in the DB"
      task :funds, [:path_to_file] => :environment do |t, args|
        NucsFund.source(args.path_to_file)
      end


      desc "Reads a file of valid GEOO1 chart string department components and stores them in the DB"
      task :departments, [:path_to_file] => :environment do |t, args|
        NucsDepartment.source(args.path_to_file)
      end


      desc "Reads a file of valid GEOO1 chart string project and activity components and stores them in the DB"
      task :projects_activities, [:path_to_file] => :environment do |t, args|
        NucsProjectActivity.source(args.path_to_file)
      end


      desc "Reads a file of valid GEOO1 chart string program components and stores them in the DB"
      task :programs, [:path_to_file] => :environment do |t, args|
        NucsProgram.source(args.path_to_file)
      end


      desc "Reads a file of valid GEOO1 chart string account components and stores them in the DB"
      task :accounts, [:path_to_file] => :environment do |t, args|
        NucsAccount.source(args.path_to_file)
      end


      desc "Reads a file of valid GEOO1 chart string chartfield1 components and stores them in the DB"
      task :chart_field1s, [:path_to_file] => :environment do |t, args|
        NucsChartField1.source(args.path_to_file)
      end

    end
  end
end
