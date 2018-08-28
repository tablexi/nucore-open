# frozen_string_literal: true

Settings.add_source!("#{Rails.root}/config/settings/stage.yml") if ENV["RAILS_ENV"] == "staging"
Settings.add_source!("#{Rails.root}/config/settings/override.yml")
Settings.reload!
