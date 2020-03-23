# frozen_string_literal: true

module SecureRooms

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if user.operator_of?(resource)
        ability.can [
          :index,
          :dashboard,
          :tab_counts,
        ], Occupancy
      end

      if user.manager_of?(resource)
        ability.can [
          :assign_price_policies_to_problem_orders,
        ], Occupancy
      end

      if user.manager_of?(resource) || user.facility_senior_staff_of?(resource)
        ability.can :manage, CardReader
        ability.can :show_problems, Occupancy
      end
    end

  end

end
