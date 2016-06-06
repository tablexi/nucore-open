module SangerSequencing

  module Admin

    class SubmissionsController < ApplicationController

      admin_tab :all
      before_filter { @active_tab = "admin_sanger_sequencing" }

      def index
        @submissions = Submission.purchased
      end

      def show
        @submission = Submission.purchased.for_facility(current_facility).find(params[:id])
      end

    end

  end

end
