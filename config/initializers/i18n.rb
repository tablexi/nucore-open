# Once Rails has its defaults configured augment the base i18n translations
Rails.configuration.after_initialize do
  # Keep locale overrides in a subdir of config/locales so that
  # they are not picked up by the loading of the i18n framework.
  Dir[ Rails.root.join('config', 'locales', 'override', '*.yml') ].each do |file|
    override=YAML.load_file file
    override.each{|locale, translations| I18n.backend.store_translations locale, translations }
  end
end