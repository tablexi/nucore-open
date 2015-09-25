require 'yaml'
require 'erb'

puts "Loading database config"
config_file_path = File.expand_path('../../../config/database.yml', __FILE__)
erb = ERB.new(File.read(config_file_path)).result
config = YAML.load( erb )

sql_file = File.expand_path("../setup.sql", __FILE__)

begin
  puts "Creating database users"
  connection_string = "system/oracle@#{config["development"]["database"]}"
  output = `sqlplus #{connection_string} < #{sql_file}`
  puts output
# On a fresh create, it may take a few seconds for oracle server to come up,
# so rety this block until we create the user
end until output.include?("User created.")

