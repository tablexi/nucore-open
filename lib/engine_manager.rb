# Keeper of this app's loaded engines
class EngineManager

  def self.loaded_engines
    Rails.application.railties.engines.map { |e| e.class.name }.to_set
  end

  def self.engine_loaded?(engine_name)
    class_name = "#{engine_name.to_s.camelize}::Engine"
    loaded_engines.include?(class_name)
  end

end
