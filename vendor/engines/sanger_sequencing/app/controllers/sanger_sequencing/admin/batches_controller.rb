module SangerSequencing

  module Admin

    class BatchesController < BaseController

      admin_tab :all
      layout "two_column", only: [:index]
      before_filter(only: :index) { @active_tab = "admin_sanger_sequencing" }

      def index
        @batches = Batch.order(created_at: :desc).paginate(page: params[:page])
      end

      def new
        @submissions = Submission.ready_for_batch.for_facility(current_facility)
        @batch = BatchForm.new
      end

      def create
        @batch = BatchForm.new

        # Whitelisting should happen in the form object
        if @batch.update_attributes(params[:batch].merge(created_by: current_user))
          redirect_to [current_facility, :sanger_sequencing, :admin, :submissions], notice: text("create.success")
        else
          @submissions = Submission.ready_for_batch.for_facility(current_facility)
          flash.now[:alert] = @batch.errors.map { |_k, msg| msg }.to_sentence
          render :new
        end
      end

      def destroy
        @batch = Batch.find(params[:id])
        @batch.destroy
        redirect_to facility_sanger_sequencing_admin_batches_path, notice: text("destroy.success")
      end

    end

  end

end
