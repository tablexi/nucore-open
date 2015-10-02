require 'yaml'
require 'erb'

puts "Loading database config"
config_file_path = File.expand_path('../../../config/database.yml', __FILE__)
erb = ERB.new(File.read(config_file_path)).result
config = YAML.load( erb )

puts "Creating database users"
sql_file = File.expand_path("../setup.sql", __FILE__)

connection_string = "system/oracle@#{config["development"]["database"]}"
`sqlplus #{connection_string} < #{sql_file}`
