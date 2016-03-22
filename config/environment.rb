# Load the rails application
require File.expand_path("../application", __FILE__)

# Initialize the rails application
Nucore::Application.initialize!

# TODO:
# MySQL 5.7+ does not allow NULL primary keys, but older versions of Rails
# create primary key columns DEFAULT NULL.
#
# Remove this require and the patch file itself after upgrading to Rails 4.
# https://github.com/rails/rails/pull/13247#issuecomment-32425844
if Rails.version < "4"
  if defined?(ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter)
    require File.expand_path("../../lib/patches/abstract_mysql_adapter", __FILE__)
  end
else
  raise "Remove the reference to the abstract_mysql_adapter patch in #{__FILE__} for Rails 4+"
end
