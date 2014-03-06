
# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

#
# Check for engine factories. If they exist and the engine is in use load it up
Dir[File.expand_path('vendor/engines/*', Rails.root)].each do |engine|
  engine_name=File.basename engine
  factory_file=File.join(engine, 'spec/factories.rb')
  require factory_file if File.exist?(factory_file) && EngineManager.engine_loaded?(engine_name)
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.use_transactional_fixtures = true

  config.include Devise::TestHelpers, :type => :controller

  config.include FactoryGirl::Syntax::Methods

  config.around(:each, :timecop_freeze) do |example|
    # freeze time to specific time by defining let(:now)
    time = defined?(now) ? now : Time.zone.now
    Timecop.freeze time do
      example.call
    end
  end

  config.before(:all) do
    # users are not created within transactions, so delete them all here before running tests
    UserRole.delete_all
    User.delete_all

    # initialize order status constants
    @os_new        = OrderStatus.find_or_create_by_name('New')
    @os_in_process = OrderStatus.find_or_create_by_name('In Process')
    @os_complete   = OrderStatus.find_or_create_by_name('Complete')
    @os_cancelled  = OrderStatus.find_or_create_by_name('Cancelled')
    @os_reconciled  = OrderStatus.find_or_create_by_name('Reconciled')

    # initialize affiliates
    Affiliate.find_or_create_by_name('Other')

    # initialize price groups
    @nupg = PriceGroup.find_or_create_by_name(:name => Settings.price_group.name.base, :is_internal => true, :display_order => 1)
    @nupg.save(:validate => false)
    @ccpg = PriceGroup.find_or_create_by_name(:name => Settings.price_group.name.cancer_center, :is_internal => true, :display_order => 2)
    @ccpg.save(:validate => false)
    @epg = PriceGroup.find_or_create_by_name(:name => Settings.price_group.name.external, :is_internal => false, :display_order => 3)
    @epg.save(:validate => false)

    #now=Time.zone.parse("#{Date.today.to_s} 09:30:00")
    Timecop.return
    now=(SettingsHelper::fiscal_year_beginning(Date.today) + 1.year + 10.days).change(:hour => 9, :min => 30)
    #puts "travelling to #{now}"
    Timecop.travel(now)
  end
end
