# frozen_string_literal: true

require "yaml"
require "erb"

puts "Loading database config"
config_file_path = File.expand_path("../../../config/database.yml", __FILE__)
erb = ERB.new(File.read(config_file_path)).result
# (yaml, whitelist_classes, whitelist_symbols, allow_aliases)
config = YAML.safe_load(erb, [], [], true)

sql_file = File.expand_path("../setup.sql", __FILE__)

loop do
  puts "Creating database users"
  connection_string = "system/oracle@#{config['development']['database']}"
  output = `sqlplus #{connection_string} < #{sql_file}`
  puts output
  break if output.include?("User created.")
  # On a fresh create, it may take a few seconds for oracle server to come up,
  # so rety this block until we create the user
end
