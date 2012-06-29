#
# Keeper of this app's loaded engines
class EngineManager

  @@loaded_engines={}

  def self.engine_loaded?(engine_name)
    normalized=engine_name.to_s.camelize.to_sym

    unless @@loaded_engines.has_key? normalized
      @@loaded_engines[normalized]=Rails.application.railties.engines.any?{|e| e.class.name.start_with? normalized.to_s }
    end

    @@loaded_engines[normalized]
  end

end