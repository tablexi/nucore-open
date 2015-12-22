# Rspec configurations for this engine
RSpec.configure do |config|

  # Skip split_accounts tests if split_accounts feature is disabled
  unless SettingsHelper.feature_on?(:split_accounts)
    config.filter_run_excluding split_accounts: true
  end

end
