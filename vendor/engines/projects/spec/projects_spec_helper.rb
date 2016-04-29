RSpec.configure do |config|
  config.before(:all) { Projects::Engine.enable! }
end
