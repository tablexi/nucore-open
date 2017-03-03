module SecureRooms

  class CardNumberAbility

    include CanCan::Ability

    def initialize(user, facility)
      return unless user && facility

      if user.administrator? || user.operator_of?(facility)
        can :edit, User
      end
    end

  end

end
