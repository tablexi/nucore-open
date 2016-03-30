module Projects

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      ability.can([:index, :new], Projects::Project) if user.operator_of?(resource)
    end
  end

end
