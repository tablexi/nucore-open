require "spec_helper"

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "shoulda/matchers"
#
# Check for engine factories. If they exist and the engine is in use load it up
Dir[File.expand_path("vendor/engines/*", Rails.root)].each do |engine|
  engine_name = File.basename engine
  factory_file = File.join(engine, "spec/factories.rb")
  require factory_file if File.exist?(factory_file) && EngineManager.engine_loaded?(engine_name)
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|

  # rspec-rails by default excludes stack traces from within vendor Lots of our
  # engines are under vendor, so we don't want to exclude them
  config.backtrace_exclusion_patterns.delete(%r{vendor/})

  config.use_transactional_fixtures = true

  require "capybara/poltergeist"
  Capybara.javascript_driver = :poltergeist
  require "capybara/email/rspec"

  config.include Devise::TestHelpers, type: :controller
  config.include FactoryGirl::Syntax::Methods

  config.around(:each) do |example|
    if example.metadata[:feature_setting]
      example.metadata[:feature_setting].each do |feature, value|
        SettingsHelper.enable_feature(feature, value)
      end
      Nucore::Application.reload_routes!

      example.run

      Settings.reload!
      Nucore::Application.reload_routes!
    else
      example.run
    end
  end

  config.before(:all) do
    # users are not created within transactions, so delete them all here before running tests
    UserRole.delete_all
    User.delete_all

    # initialize order status constants
    @os_new        = OrderStatus.find_or_create_by(name: "New")
    @os_in_process = OrderStatus.find_or_create_by(name: "In Process")
    @os_complete   = OrderStatus.find_or_create_by(name: "Complete")
    @os_canceled   = OrderStatus.find_or_create_by(name: "Canceled")
    @os_reconciled = OrderStatus.find_or_create_by(name: "Reconciled")

    # initialize affiliates
    Affiliate.find_or_create_by(name: "Other")

    # initialize price groups
    @nupg = PriceGroup.find_or_create_by(name: Settings.price_group.name.base, is_internal: true, display_order: 1)
    @nupg.save(validate: false)
    @ccpg = PriceGroup.find_or_create_by(name: Settings.price_group.name.cancer_center, is_internal: true, display_order: 2)
    @ccpg.save(validate: false)
    @epg = PriceGroup.find_or_create_by(name: Settings.price_group.name.external, is_internal: false, display_order: 3)
    @epg.save(validate: false)

    # now=Time.zone.parse("#{Date.today.to_s} 09:30:00")
    Timecop.return
    now = (SettingsHelper.fiscal_year_beginning(Date.today) + 1.year + 10.days).change(hour: 9, min: 30)
    # puts "travelling to #{now}"
    Timecop.travel(now)
  end

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!

  require "text_helpers/rspec"

  config.before(:suite) do
    TextHelpers::RSpec.setup_spec_translations
  end

  config.after(:each, :locales) do
    TextHelpers::RSpec.reset_spec_translations
  end

  def facilities_route
    I18n.t("facilities_downcase")
  end

  config.include Warden::Test::Helpers, type: :feature
  config.after type: :feature do
    Warden.test_reset!
  end

  require "rspec/active_job"
  config.include(RSpec::ActiveJob)

end

FactoryGirl::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end
