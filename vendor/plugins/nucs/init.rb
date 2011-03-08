# use the host app's db config during development
unless Rails.env.production?
  require 'fileutils'
  base=File.dirname(__FILE__)
  FileUtils.ln_sf(File.join(base, '..', '..', '..', 'config', 'database.yml'), File.join(base, 'config', 'database.yml'))
end