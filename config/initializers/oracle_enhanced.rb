# Be sure to restart your server when you modify this file.

# configuration of the oracle_enhanced activerecord adapter

ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.class_eval do
  self.emulate_integers_by_column_name = true
  self.default_sequence_start_value = 1
end