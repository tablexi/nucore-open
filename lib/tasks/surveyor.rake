namespace :surveyor do
  # similar to surveyor:parse, but uses absolute file path
  desc "generate and load survey (specify FILE=/tmp/files/surveys/your_survey.rb)"
  task :import => :environment do
    raise "USAGE: file name required e.g. 'FILE=/tmp/files/surveys/kitchen_sink_survey.rb'" if ENV["FILE"].blank?
    file = ENV["FILE"]
    raise "File does not exist: #{file}" unless FileTest.exists?(file)
    puts "--- Parsing #{file} ---"
    Surveyor::Parser.parse File.read(file)
    puts "--- Done #{file} ---"
  end
  
end