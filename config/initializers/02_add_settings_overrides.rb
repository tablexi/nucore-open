Settings.add_source!("#{Rails.root}/config/settings/stage.yml") if ENV["RAILS_ENV"] == "stage"
Settings.add_source!("#{Rails.root}/config/settings/override.yml")
Settings.reload!
