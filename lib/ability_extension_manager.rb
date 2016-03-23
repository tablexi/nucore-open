class AbilityExtensionManager

  def self.extensions
    @extensions ||= []
  end

  attr_reader :ability

  def initialize(ability)
    @ability = ability
  end

  def extend(user, resource)
    self.class.extensions.each do |extension|
      extension.constantize.new(ability).extend(user, resource)
    end
  end

end
