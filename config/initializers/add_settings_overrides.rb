Settings.add_source!("#{Rails.root}/config/settings/stage.yml")
Settings.add_source!("#{Rails.root}/config/settings/override.yml")
Settings.reload!
