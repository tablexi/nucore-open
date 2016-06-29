module SangerSequencing

  module Admin

    class BatchesController < BaseController

      admin_tab :all
      # layout "two_column"
      # before_filter { @active_tab = "admin_sanger_sequencing" }

      def new
        @submissions = Submission.ready_for_batch.for_facility(current_facility)
        @batch = BatchForm.new
      end

      def create
        @batch = BatchForm.new

        # Whitelisting should happen in the form object
        if @batch.update_attributes(params[:batch].merge(created_by: current_user))
          flash[:notice] = "We have saved your batch"
          redirect_to [current_facility, :sanger_sequencing, :admin, :submissions]
        else
          @submissions = Submission.ready_for_batch.for_facility(current_facility)
          flash.now[:alert] = @batch.errors.map { |_k, msg| msg }.to_sentence
          render :new
        end
      end

    end

  end

end
