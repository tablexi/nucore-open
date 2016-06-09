module SangerSequencing

  class Ability

    include CanCan::Ability

    def initialize(user, facility = nil)
      return unless user

      can [:show, :create, :update, :fetch_ids], Submission, user: user

      if facility && user.operator_of?(facility)
        can [:index, :show], Submission
      end
    end

  end

end
