source "https://rubygems.org"

ruby File.open(File.expand_path(".ruby-version", File.dirname(__FILE__))) { |f| f.read.chomp }

git_source(:github) { |repo_name| "git@github.com:#{repo_name}.git" }

## base
gem "rails", "5.0.7"
gem "config"

## database
gem "mysql2", "~> 0.4.10"
# To use Oracle, remove the mysql2 gem above and uncomment these lines
# gem "ruby-oci8"
# gem "activerecord-oracle_enhanced-adapter"

## auth
gem "cancancan"
gem "devise"
gem "devise-encryptable"

## models
gem "aasm"
gem "paperclip"
gem "paper_trail"
gem "awesome_nested_set"
gem "nokogiri"
gem "rails-observers"
gem "icalendar"
gem "paranoia"

## views
gem "sass-rails"
gem "coffee-rails"
gem "uglifier"
gem "therubyracer"
gem "bootstrap-sass", "~> 2.3.2" # will not upgrade
gem "haml"
gem "will_paginate"
gem "dynamic_form"
gem "ckeditor"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "vuejs-rails", "~> 1.0.26" # 2.0 introduces breaking changes
gem "clockpunch"
gem "simple_form"
gem "font-awesome-rails"
gem "nested_form_fields"
gem "text_helpers"
gem "chosen-rails"
gem "fine_uploader", path: "vendor/engines/fine_uploader"
gem "fullcalendar", path: "vendor/engines/fullcalendar"
gem "rubyzip"

## controllers
gem "prawn"
gem "prawn_rails"
gem "prawn-table"

## other
gem "delayed_job_active_record"
gem "fog-aws"
gem "rake"
gem "spreadsheet"
gem "daemons"
gem "ice_cube"

## custom
gem "bulk_email", path: "vendor/engines/bulk_email"
gem "c2po", path: "vendor/engines/c2po"
gem "dataprobe", path: "vendor/engines/dataprobe"
gem "ldap_authentication", path: "vendor/engines/ldap_authentication"
gem "saml_authentication", path: "vendor/engines/saml_authentication"
gem "projects", path: "vendor/engines/projects"
gem "sanger_sequencing", path: "vendor/engines/sanger_sequencing"
gem "secure_rooms", path: "vendor/engines/secure_rooms"
gem "split_accounts", path: "vendor/engines/split_accounts"
gem "synaccess_connect"

group :development do
  gem "bullet" # Detect N+1s and recommends eager loading
  gem "coffeelint"
  gem "haml_lint"
  gem "letter_opener"
  gem "rails-erd"
  gem "rubocop", "0.58", require: false # needs to be updated in sync with available codeclimate channels
  gem "rubocop-rspec"
  gem "web-console"
end

group :development, :deployment do
  gem "capistrano",         require: false
  gem "capistrano-rails",   require: false
  gem "capistrano-rvm",     require: false
  gem "capistrano-bundler", require: false

  # net-ssh 4.2 requires the gems below to support ed25519 keys
  # for deploying via capistrano
  # more info at https://github.com/net-ssh/net-ssh/issues/478
  gem "bcrypt_pbkdf", ">= 1.0", "< 2.0", require: false
  gem "rbnacl", ">= 3.2", "< 5.0", require: false
  gem "rbnacl-libsodium", require: false
end

group :development, :test do
  gem "awesome_print"
  gem "factory_bot_rails"
  gem "guard-rspec", require: false
  gem "guard-teaspoon", require: false
  gem "pry-rails"
  gem "pry-byebug"
  gem "rspec-rails"
  gem "rspec-activejob"
  gem "spring"
  gem "spring-commands-rspec"
  gem "teaspoon-jasmine"
  gem "thin"
end

group :test do
  gem "rspec_junit_formatter"
  gem "ci_reporter_rspec"
  gem "codeclimate_circle_ci_coverage"
  gem "capybara"
  gem "capybara-email"
  gem "poltergeist"
  gem "rails-controller-testing"
  gem "rspec-collection_matchers"
  gem "shoulda-matchers", github: "thoughtbot/shoulda-matchers" # https://github.com/thoughtbot/shoulda-matchers/issues/913
  gem "single_test"
end

group :stage, :production do
  gem "eye-patch", require: false
  gem "exception_notification"
  gem "lograge"
  gem "logstash-event"
  gem "oj"
  # 2.15.6 has a problem during cap deploy
  # https://github.com/rollbar/rollbar-gem/issues/713
  gem "rollbar", "2.15.5"
  gem "unicorn", require: false
  gem "whenever", require: false
end
