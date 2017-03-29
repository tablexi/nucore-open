module SecureRooms

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      ability.can :manage, CardReader if user.manager_of?(resource) || user.facility_senior_staff_of?(resource)
    end

  end

end
