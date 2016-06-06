module SangerSequencing

  class Ability

    include CanCan::Ability

    def initialize(user)
      can [:show, :create, :update, :fetch_ids], Submission, user: user
    end

  end

end
