# From https://github.com/railscasts/391-testing-javascript-with-phantomjs/blob/master/checkout-after/spec/support/share_db_connection.rb
# Allows Poltergeist/Capybara to share a DB connection so we can keep using transactional_fixtures
class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
