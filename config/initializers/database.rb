# Be sure to restart your server when you modify this file.

File.open("#{Rails.root}/config/database.yml") do |yml|
  config=YAML.load(yml)

  if config[Rails.env]['adapter'] == 'oracle_enhanced'
    ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.class_eval do
      self.emulate_integers_by_column_name = true
      self.default_sequence_start_value = 1
    end
  else
    ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
      require File.join(Rails.root, 'lib', 'mysql_driver_extension')
      include MysqlDriverExtension
    end
  end
end