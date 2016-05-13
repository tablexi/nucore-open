# TODO: Remove in Rails 4
# In Ruby 2.3, Hash responds to `to_proc`. This causes problems with associations.
# This is fixed in Rails 4+
# https://github.com/rails/rails/issues/25010
#
if RUBY_VERSION >= "2.3.0"
  raise "Remove hash fix for ruby 2.3" if Rails.version >= "4"
  class Hash
    undef_method :to_proc
  end
end
