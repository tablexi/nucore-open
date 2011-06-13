# Temporary fix for uninitialized constant ActiveSupport::Dependencies::Mutex, see http://stackoverflow.com/questions/5564251/uninitialized-constant-activesupportdependenciesmutex
require 'thread'

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

begin
  require 'single_test'
  SingleTest.load_tasks
rescue LoadError
  # ignore
end

require 'rubygems'
require 'ci/reporter/rake/rspec'
