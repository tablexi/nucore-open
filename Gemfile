source :gemcutter

gem 'aasm',             '2.2.0'
gem 'mysql2',           '0.2.11'
gem 'activerecord-oracle_enhanced-adapter', '1.3.0'
gem 'capistrano',       '2.6.0'
gem 'paperclip',        '2.3.12'
gem 'rails',            '3.0.10'
gem 'rake',             '0.8.7'
gem 'ruby-ole',         '1.2.11.1'
# ruby-oci8 won't compile on lion
unless (RUBY_PLATFORM == "x86_64-darwin11.0.1")
  gem 'ruby-oci8',        '2.0.4'
end
gem 'haml',             '3.1.2'
gem 'spreadsheet',      '0.6.5.5'
gem 'vestal_versions',  '1.2.4.3', :git => 'git://github.com/elzoiddy/vestal_versions.git'
gem 'will_paginate',    '3.0.2'
gem 'fast-aes',         '0.1.1'
gem 'pdf-reader',       '0.8.6'
gem 'prawn',            '0.11.1.pre'
gem 'prawn_rails',      '0.0.5'
gem 'devise',           '1.3.4'
gem 'cancan',           '1.6.5'
gem 'nokogiri',         '1.4.4'
gem 'devise_ldap_authenticatable', '0.4.4'
gem 'jquery-rails',     '1.0.12'
gem 'foreigner',        '1.1.1'
gem 'awesome_nested_set', '2.0.1'
gem 'exception_notification', :require => 'exception_notifier'
gem 'daemons',          '1.1.6'
gem 'rails_config',     '0.2.5'

group :development, :test do
   gem 'autotest',          '4.4.6' # TODO: remove?
   gem 'autotest-rails',    '4.1.0' # TODO: remove?
   gem 'ci_reporter'
   gem 'factory_girl_rails','1.0.1'
   gem 'mocha',             '0.9.7' # TODO: remove?
   gem 'rspec-rails',       '2.6.1'
   gem 'ruby-debug19',      '0.11.6'
   gem 'shoulda',           '2.11.3'
   gem 'single_test',       '0.4.0'
   gem 'spork',             '0.9.0.rc9'
   gem 'timecop'
   gem 'ZenTest',           '4.5.0' # TODO: remove?
   #gem 'sqlite3-ruby'
end

