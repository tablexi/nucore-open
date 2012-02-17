# use the host app's db config during development
unless Rails.env.production?
  require 'fileutils'
  base=File.dirname(__FILE__)
  FileUtils.ln_sf(File.join(base, '..', '..', '..', '..', '..', 'config', 'database.yml'), File.join(base, '..', 'database.yml'))
  FileUtils.ln_sf(File.join(base, '..', '..', '..', '..', '..', 'Gemfile'), File.join(base, '..', '..', 'Gemfile'))
  FileUtils.ln_sf(File.join(base, '..', '..', '..', '..', '..', 'Gemfile.lock'), File.join(base, '..', '..', 'Gemfile.lock'))
end