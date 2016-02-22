# TODO:
# MySQL 5.7+ does not allow NULL primary keys, but older versions of Rails
# create primary key columns DEFAULT NULL.
#
# Remove this file and its environment.rb reference after upgrading to Rails 4.
#
# https://github.com/rails/rails/pull/13247#issuecomment-32425844
class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
end
