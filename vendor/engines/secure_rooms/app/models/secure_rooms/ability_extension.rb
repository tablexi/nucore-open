module SecureRooms

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      ability.can :manage, CardReader if user.manager_of?(resource) || user.facility_senior_staff_of?(resource)
      if user.operator_of?(resource)
        ability.can [
          :index,
          :dashboard,
          :show_problems,
          :assign_price_policies_to_problem_orders,
          :tab_counts,
        ], Occupancy
      end
    end

  end

end
