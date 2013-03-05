source :gemcutter

## base
gem 'rails',            '3.0.19'
gem 'rails_config',     '0.2.5'

## database
gem 'mysql2',           '0.2.11'
gem 'foreigner',        '1.1.1'

## deployment
gem 'capistrano',       '2.6.0'

## auth
gem 'devise',           '1.3.4'
gem 'cancan',           '1.6.8'
gem 'devise_ldap_authenticatable', '0.4.4'

## models
gem 'aasm',             '2.2.0'
gem 'paperclip',        '2.3.12'
gem 'vestal_versions',  '1.2.4.3', :git => 'git://github.com/elzoiddy/vestal_versions.git'
gem 'awesome_nested_set', '2.0.1'
gem 'nokogiri',         '1.4.4'

## views
gem 'haml',             '3.1.2'
gem 'will_paginate',    '3.0.2'
gem 'jquery-rails',     '1.0.12'

## controllers
gem 'prawn',            '0.12'
gem 'prawn_rails',      '0.0.5'

## other
gem 'rake'
gem 'ruby-ole',         '1.2.11.1'
gem 'spreadsheet',      '0.6.5.5'
gem 'fast-aes',         '0.1.1'
gem 'pdf-reader',       '1.3.2'
gem 'exception_notification', :require => 'exception_notifier'
gem 'daemons',          '1.1.6'

## custom
gem 'c2po',             '~> 1.0.0', :path => 'vendor/engines/c2po'

group :development, :test do
  gem 'ci_reporter'
  # TODO upgrade factory girl to 4.1 once we no longer need to support
  # ruby 1.8.7. FactoryGirl 3 only supports 1.9.2
  gem 'factory_girl_rails','1.7.0'
  gem 'rspec-rails',       '2.9'
  gem 'ruby-debug19',      '0.11.6'
  gem 'shoulda-matchers',  '1.4.2'
  gem 'single_test',       '0.4.0'
  gem 'spork',             '0.9.0.rc9'
  gem 'timecop'
  gem "pry-rails",         '0.2.2'
  gem "awesome_print",     '1.1.0'
end

group :oracle do
  # ruby-oci8 won't compile on lion
  unless RUBY_PLATFORM =~ /(?:i686|x86_64)-darwin(?:11|12)/
    gem 'ruby-oci8',        '2.0.4'
  end

  gem 'activerecord-oracle_enhanced-adapter', '1.3.0'
end
