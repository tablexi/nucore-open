module SangerSequencing

  module Admin

    class AdminController < SangerSequencing::BaseController

      check_authorization

      def current_ability
        SangerSequencing::Ability.new(current_user, current_facility)
      end

    end

  end

end
