

require "nucore_kfs/collector_export"
require "nucore_kfs/uch_banner_export"
require "nucore_kfs/chart_of_accounts"
require "nucore_kfs/import_uch_banner_index"
require "nucore_kfs/collector_row"

module NucoreKfs
  class Engine < ::Rails::Engine

    config.to_prepare do
      ViewHook.add_hook "facility_journals.downloads",
                        "other_formats",
                        "kfs_csv_partial"
                        
      ViewHook.add_hook "facility_journals.downloads",
                        "other_formats",
                        "uch_banner_csv_partial"
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end

  end

end