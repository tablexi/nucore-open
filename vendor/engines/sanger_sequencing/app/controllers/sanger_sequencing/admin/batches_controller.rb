module SangerSequencing

  module Admin

    class BatchesController < BaseController

      admin_tab :all
      # layout "two_column"
      # before_filter { @active_tab = "admin_sanger_sequencing" }

      def new
        @submissions = Submission.ready_for_batch.for_facility(current_facility)
      end

    end

  end

end
