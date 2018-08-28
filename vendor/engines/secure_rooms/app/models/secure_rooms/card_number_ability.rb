# frozen_string_literal: true

module SecureRooms

  class CardNumberAbility

    include CanCan::Ability

    def initialize(user, facility)
      return unless user && facility

      can :edit, User if user.administrator? || user.operator_of?(facility)
    end

  end

end
