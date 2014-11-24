source 'https://rubygems.org'

## base
gem 'rails',            '3.2.21'
gem 'rails_config',     '0.3.3'

## database
gem 'mysql2',           '~> 0.3.17'
gem 'foreigner',        '1.6.1'
gem 'immigrant' # finding missing foreign keys

## deployment
gem 'capistrano',       '2.15.4'

## auth
gem 'devise',           '~>2.2.8'
gem 'devise-encryptable', '0.1.2'
gem 'devise_ldap_authenticatable', '~>0.7.0'
gem 'cancan',           '1.6.10'

## models
gem 'aasm',             '2.2.0'
gem 'paperclip',        '~> 4.2.0'
gem 'vestal_versions',  '1.2.4.3', github: 'elzoiddy/vestal_versions'
gem 'awesome_nested_set', '2.1.6'
gem 'nokogiri',         '~> 1.6.1'

## views
gem 'bootstrap-sass',   '~> 2.3.2'
gem 'haml',             '~> 4.0.5'
gem 'will_paginate',    '~> 3.0.5'
gem 'dynamic_form',     '~> 1.1.4'
gem 'ckeditor',         '~> 4.0.10'
gem 'jquery-rails',     '~> 2.1.4'
gem 'jquery-ui-sass-rails'
gem 'clockpunch',       '~> 0.1.0'
gem 'simple_form',      '~> 2.1.1'
gem 'font-awesome-rails', '~> 3.2.0'

## controllers
gem 'prawn',            '0.12'
gem 'prawn_rails',      '0.0.11'

## other
gem 'delayed_job_active_record', '~> 4.0.1'
gem 'rake'
gem 'spreadsheet',      '~> 0.6.5.5'
gem 'fast-aes',         '0.1.1'
gem 'pdf-reader',       '1.3.3'
gem 'exception_notification', '~> 4.0.1'
gem 'daemons',          '1.1.9'

## custom
gem 'c2po',             '~> 1.0.0', path: 'vendor/engines/c2po'
gem 'dataprobe',        '~> 1.0.0', path: 'vendor/engines/dataprobe'
gem 'synaccess_connect', '0.2.2', github: 'tablexi/synaccess'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :development, :test do
  gem 'awesome_print',     '1.1.0'
  gem 'ci_reporter'
  gem 'factory_girl_rails','4.2.1'
  gem 'guard-rspec', require: false
  gem 'pry-rails',         '~> 0.3.2'
  gem 'pry-byebug',        '~> 2.0.0'
  gem 'quiet_assets'
  gem 'rspec-rails',       '2.14.0'
  gem 'shoulda-matchers',  '2.4'
  gem 'single_test',       '0.4.0'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'thin'
  gem 'timecop',           '~> 0.6.3'
end

group :assets do
  gem 'sass-rails',   '~> 3.2.6'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier',     '>= 2.1.1'
  gem 'therubyracer'
  gem 'turbo-sprockets-rails3'
end

group :oracle do
  # ruby-oci8 won't compile on lion
  unless RUBY_PLATFORM =~ /(?:i686|x86_64)-darwin(?:11|12)/
    gem 'ruby-oci8',        '2.1.7'
  end

  gem 'activerecord-oracle_enhanced-adapter', '1.4.2'
end
