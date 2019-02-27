

require "nucore_kfs/collector_export"

module NucoreKfs
  class Engine < ::Rails::Engine

    config.to_prepare do
      ViewHook.add_hook "facility_journals.downloads",
                        "other_formats",
                        "kfs_csv_partial"
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

  end

end
