module SecureRooms

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if user_has_facility_role?(user)
        ability.can :edit, User
        ability.can :update, User
      end

      if user_has_facility_role?(user) || user.administrator?
        ability.can :update_indala_number, User
      end
    end

    private def user_has_facility_role?(user)
      (user.user_roles.map(&:role) & UserRole.facility_roles).any?
    end

  end

end
