module SangerSequencing

  module Admin

    class SubmissionsController < ApplicationController

      admin_tab :all
      before_filter { @active_tab = "admin_sanger_sequencing" }

      def index
        sanger_ability.authorize! :index, Submission
        @submissions = Submission.purchased
      end

      def show
        @submission = Submission.purchased.for_facility(current_facility).find(params[:id])
        sanger_ability.authorize! :show, @submission
      end

      private

      def sanger_ability
        SangerSequencing::Ability.new(current_user, current_facility)
      end

    end

  end

end
