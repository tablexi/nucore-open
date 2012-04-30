unless Rails.env.production?
  require 'fileutils'
  base=File.dirname(__FILE__)

  #
  # Use the host app's config during development
  FileUtils.ln_sf File.expand_path('../../../../../config/database.yml', base), File.expand_path('../database.yml', base)
  FileUtils.ln_sf File.expand_path('../../../../../Gemfile', base), File.expand_path('../../Gemfile', base)
  FileUtils.ln_sf File.expand_path('../../../../../Gemfile.lock', base), File.expand_path('../../Gemfile.lock', base)

  #
  # These specs should be integrated into the main app's spec run
  %w(models controllers).each do |spec_dir|
    integrate_path=File.expand_path("../../../../../spec/#{spec_dir}/nucs", base)
    # must integrate via a real directory (i.e. can't symlink dir) or rspec won't find specs
    FileUtils.mkdir integrate_path unless File.exists? integrate_path

    Dir[File.expand_path("../../spec/core/#{spec_dir}/*_spec.rb", base)].each do |spec|
      FileUtils.ln_sf spec, integrate_path
    end
  end
end