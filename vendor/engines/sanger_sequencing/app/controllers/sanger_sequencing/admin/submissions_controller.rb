module SangerSequencing

  module Admin

    class SubmissionsController < BaseController

      admin_tab :all
      layout "two_column"
      before_filter { @active_tab = "admin_sanger_sequencing" }

      def index
        sanger_ability.authorize! :index, Submission
        @submissions = Submission.purchased.for_facility(current_facility).paginate(page: params[:page])
      end

      def show
        @submission = Submission.purchased.for_facility(current_facility).find(params[:id])
        sanger_ability.authorize! :show, @submission
        render layout: false if modal?
      end

      private

      def sanger_ability
        SangerSequencing::Ability.new(current_user, current_facility)
      end

      def modal?
        request.xhr?
      end
      helper_method :modal?

    end

  end

end
