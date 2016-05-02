module Projects

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if user.operator_of?(resource)
        ability.can([:create, :index, :new, :show], Projects::Project)
      end
    end

  end

end
