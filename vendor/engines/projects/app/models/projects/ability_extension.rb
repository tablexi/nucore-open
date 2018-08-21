# frozen_string_literal: true

module Projects

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if user.operator_of?(resource)
        ability.can([:create, :edit, :inactive, :index, :new, :show, :update], Projects::Project)
      end
    end

  end

end
