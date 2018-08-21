# frozen_string_literal: true

# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

# Include tasks from other gems included in your Gemfile
require "capistrano/rvm"
require "capistrano/rails"
require "eye/patch/capistrano3"
require "rollbar/capistrano3"
require "whenever/capistrano"

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git
