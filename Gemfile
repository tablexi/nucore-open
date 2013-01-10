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
gem 'prawn',            '0.11.1.pre'
gem 'prawn_rails',      '0.0.5'

## other
gem 'rake'
gem 'ruby-ole',         '1.2.11.1'
gem 'spreadsheet',      '0.6.5.5'
gem 'fast-aes',         '0.1.1'
gem 'pdf-reader',       '0.8.6'
gem 'exception_notification', :require => 'exception_notifier'
gem 'daemons',          '1.1.6'

## custom
gem 'c2po',             '~> 1.0.0', :path => 'vendor/engines/c2po'

group :development, :test do
  gem 'ci_reporter'
  gem 'factory_girl_rails','4.1.0'
  gem 'mocha',             '0.9.7'
  gem 'rspec-rails',       '2.9'
  gem 'ruby-debug19',      '0.11.6'
  gem 'shoulda',           '2.11.3'
  gem 'single_test',       '0.4.0'
  gem 'spork',             '0.9.0.rc9'
  gem 'timecop'
end

group :oracle do
  # ruby-oci8 won't compile on lion
  unless RUBY_PLATFORM =~ /x86_64-darwin(11|12)/
    gem 'ruby-oci8',        '2.0.4'
  end

  gem 'activerecord-oracle_enhanced-adapter', '1.3.0'
end
