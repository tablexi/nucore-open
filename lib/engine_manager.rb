# frozen_string_literal: true

# Keeper of this app's loaded engines
class EngineManager

  def self.loaded_engines
    Rails.application.railties
         .select { |r| r.class < Rails::Engine }
         .map(&:class).to_set
  end

  def self.loaded_nucore_engines
    loaded_engines.select { |e| e.root.to_s =~ %r(/vendor/engines/\w+\z) }
  end

  def self.engine_loaded?(engine_name)
    class_name = "#{engine_name.to_s.camelize}::Engine"
    loaded_engines.map(&:name).include?(class_name)
  end

end
