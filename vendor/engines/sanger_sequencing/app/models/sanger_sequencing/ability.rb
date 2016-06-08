module SangerSequencing

  class Ability

    include CanCan::Ability

    def initialize(user, facility = nil)
      return unless user

      can [:show, :create, :update, :fetch_ids], Submission, user: user

      if facility
        can [:index, :show], Submission if user.operator_of?(facility)
      end
    end

  end

end
