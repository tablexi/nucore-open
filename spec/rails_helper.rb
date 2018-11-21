# frozen_string_literal: true

require "spec_helper"

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "shoulda/matchers"

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
  Capybara.server = :webrick
  require "capybara/email/rspec"

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include FactoryBot::Syntax::Methods

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

  config.around(:each) do |example|
    if example.metadata[:billing_review_period]
      original_review_period = Settings.billing.review_period
      Settings.billing.review_period = example.metadata[:billing_review_period]

      example.run

      Settings.billing.review_period = original_review_period
    else
      example.run
    end
  end

  config.before(:all) do
    # users are not created within transactions, so delete them all here before running tests
    PriceGroupMember.delete_all
    UserRole.delete_all
    User.delete_all

    # initialize order status constants
    @os_new        = OrderStatus.find_or_create_by(name: "New")
    @os_in_process = OrderStatus.find_or_create_by(name: "In Process")
    @os_complete   = OrderStatus.find_or_create_by(name: "Complete")
    @os_canceled   = OrderStatus.find_or_create_by(name: "Canceled")
    @os_reconciled = OrderStatus.find_or_create_by(name: "Reconciled")

    # initialize affiliates
    Affiliate.OTHER

    # initialize price groups
    @nupg = PriceGroup.find_or_create_by(name: Settings.price_group.name.base, is_internal: true, display_order: 1)
    @nupg.save(validate: false)
    @epg = PriceGroup.find_or_create_by(name: Settings.price_group.name.external, is_internal: false, display_order: 3)
    @epg.save(validate: false)

    # Because many specs rely on not crossing a fiscal year boundary we lock the
    # time globally. Rails's `travel_to` helper does not work well with nesting, so
    # we should use our own custom `travel_and_return` and `travel_to_and_return`
    # helpers. See TimeTravelHelpers. You can also use the spec_helper-defined
    # :time_travel metadata tag.
    travel_back
    now = (SettingsHelper.fiscal_year_beginning(Date.today) + 1.year + 10.days).change(hour: 9, min: 30)
    travel_to(now, safe: true)
  end

  # Allow specififying a Timezone for a group of tests:
  # describe "in central", time_zone: "America/Chicago" do
  config.around(:each, :time_zone) do |example|
    Time.use_zone(example.metadata[:time_zone]) { example.call }
  end

  config.after(:all) { travel_back }

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, type: :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!

  require "text_helpers/rspec"

  config.include TextHelpers::RSpec::TestHelpers, locales: true

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
  config.filter_gems_from_backtrace("activesupport", "activemodel", "activerecord", "spring")
end

FactoryBot::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
