module NucoreKfs
  class Engine < ::Rails::Engine
    config.to_prepare do
      ViewHook.add_hook "facility_journals.downloads",
                        "other_formats",
                        "kfs_csv_partial"
    end
  end
end
