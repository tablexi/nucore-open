module SecureRooms

  class IndalaAbility

    include CanCan::Ability

    def initialize(user, facility)
      return unless user && facility

      if user.administrator? || user_has_role_at_facility?(user, facility)
        can :edit, User
        can :update, User
      end
    end

    private def user_has_role_at_facility?(user, facility)
      roles_at_facility = user.user_roles.where(facility: facility)
      (roles_at_facility.map(&:role) & UserRole.facility_roles).any?
    end

  end

end
