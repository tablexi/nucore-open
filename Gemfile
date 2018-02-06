source "https://rubygems.org"

ruby File.open(File.expand_path(".ruby-version", File.dirname(__FILE__))) { |f| f.read.chomp }

git_source(:github) { |repo_name| "git@github.com:#{repo_name}.git" }

## base
gem "rails", "4.2.10"
gem "config"

## database
gem "mysql2"
group :oracle do
  gem "ruby-oci8"
  gem "activerecord-oracle_enhanced-adapter"
end
gem "where-or"

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
gem "vuejs-rails"
gem "clockpunch"
gem "simple_form"
gem "font-awesome-rails"
gem "nested_form_fields"
gem "text_helpers"
gem "chosen-rails"
gem "fine_uploader", path: "vendor/engines/fine_uploader"
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
gem "c2po", "~> 1.0.0", path: "vendor/engines/c2po"
gem "dataprobe", "~> 1.0.0", path: "vendor/engines/dataprobe"
gem "ldap_authentication", path: "vendor/engines/ldap_authentication"
gem "projects", "~> 0.0.1", path: "vendor/engines/projects"
gem "sanger_sequencing", "~> 0.0.1", path: "vendor/engines/sanger_sequencing"
gem "secure_rooms", path: "vendor/engines/secure_rooms"
gem "split_accounts", "~> 0.0.1", path: "vendor/engines/split_accounts"
gem "synaccess_connect"

group :development do
  gem "bullet" # Detect N+1s and recommends eager loading
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
  gem "rspec-collection_matchers"
  gem "shoulda-matchers"
  gem "single_test"
end

group :stage, :production do
  gem "eye-patch", require: false
  gem "exception_notification"
  gem "lograge"
  gem "logstash-event"
  gem "oj"
  gem "rollbar"
  gem "unicorn", require: false
  gem "whenever", require: false
end
