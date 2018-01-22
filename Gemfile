source "https://rubygems.org"

ruby File.open(File.expand_path(".ruby-version", File.dirname(__FILE__))) { |f| f.read.chomp }

git_source(:github) { |repo_name| "git@github.com:#{repo_name}.git" }

## base
gem "rails", "4.2.9"
gem "protected_attributes"
gem "rails_config",     "0.3.3"

## database
gem "mysql2",           "~> 0.3.20"
group :oracle do
  gem "ruby-oci8"
  gem "activerecord-oracle_enhanced-adapter"
end

## auth
gem "cancancan"
gem "devise"
gem "devise-encryptable"

## models
gem "aasm"
gem "paperclip"
gem "paper_trail"
gem "awesome_nested_set", "~> 3.1.3"
gem "nokogiri", ">= 1.8.1"
gem "rails-observers"
gem "icalendar"
gem "paranoia"

## views
gem "sass-rails", "~> 5.0.6"
gem "coffee-rails", "~> 4.2.2"
gem "uglifier"
gem "therubyracer"
gem "bootstrap-sass",   "~> 2.3.2"
gem "haml",             "~> 4.0.5"
gem "will_paginate"
gem "dynamic_form", "~> 1.1.4"
gem "ckeditor"
gem "jquery-rails"
gem "jquery-ui-rails", "~> 6.0.1"
gem "vuejs-rails"
gem "clockpunch", "~> 0.1.12"
gem "simple_form", "~> 3.5.0"
gem "font-awesome-rails"
gem "nested_form_fields"
gem "text_helpers"
gem "chosen-rails"
gem "fine_uploader", path: "vendor/engines/fine_uploader"
gem "rubyzip"

## controllers
gem "prawn",            "0.12"
gem "prawn_rails",      "0.0.11"

## other
gem "delayed_job_active_record", "~> 4.1.2"
gem "fog-aws"
gem "rake"
gem "spreadsheet"
gem "daemons"
gem "ice_cube"

## custom
gem "bulk_email", path: "vendor/engines/bulk_email"
gem "c2po", "~> 1.0.0", path: "vendor/engines/c2po"
gem "dataprobe", "~> 1.0.0", path: "vendor/engines/dataprobe"
gem "ldap_authentication", path: "vendor/engines/ldap_authentication"
gem "projects", "~> 0.0.1", path: "vendor/engines/projects"
gem "sanger_sequencing", "~> 0.0.1", path: "vendor/engines/sanger_sequencing"
gem "secure_rooms", path: "vendor/engines/secure_rooms"
gem "split_accounts", "~> 0.0.1", path: "vendor/engines/split_accounts"
gem "synaccess_connect"

group :development do
  gem "bullet"
  gem "coffeelint"
  gem "haml_lint"
  gem "letter_opener"
  gem "rails-erd"
  gem "rubocop", require: false
  gem "web-console"
end

group :development, :deployment do
  gem "capistrano",         require: false
  gem "capistrano-rails",   require: false
  gem "capistrano-rvm",     require: false
  gem "capistrano-bundler", require: false
end

group :development, :test do
  gem "awesome_print"
  gem "factory_bot_rails"
  gem "guard-rspec", require: false
  gem "guard-teaspoon", require: false
  gem "pry-rails"
  gem "pry-byebug"
  gem "rspec-rails", "~> 3.5.2"
  gem "rspec-activejob"
  gem "spring"
  gem "spring-commands-rspec"
  gem "teaspoon-jasmine"
  gem "test-unit" # why do we have this gem?
  gem "thin", ">= 1.7.2"
end

group :test do
  gem "rspec_junit_formatter"
  gem "ci_reporter_rspec"
  gem "codeclimate_circle_ci_coverage"
  gem "capybara"
  gem "capybara-email"
  gem "poltergeist"
  gem "rspec-collection_matchers"
  gem "shoulda-matchers"
  gem "single_test"
end

group :stage, :production do
  gem "eye-patch", require: false
  gem "exception_notification", "~> 4.0.1"
  gem "lograge"
  gem "logstash-event"
  gem "oj"
  gem "rollbar"
  gem "unicorn", require: false
  gem "whenever", require: false
end
