# Keeper of this app's loaded engines
class EngineManager

  @@loaded_engines = {}

  def self.engine_loaded?(engine_name)
    class_name = "#{engine_name.to_s.camelize}::Engine"

    unless @@loaded_engines.has_key?(class_name)
      @@loaded_engines[class_name] = Rails.application.railties.engines.any?{ |e| e.class.name == class_name }
    end

    @@loaded_engines[class_name]
  end

end
