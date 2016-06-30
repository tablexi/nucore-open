module SangerSequencing

  module Admin

    class BatchesController < AdminController

      admin_tab :all
      layout "two_column", only: [:index]
      before_action { @active_tab = "admin_sanger_sequencing" }
      before_action :load_batch_form, only: [:new, :create]
      before_action :load_batch, only: :destroy
      authorize_sanger_resource class: "SangerSequencing::Batch"

      def index
        @batches = Batch.for_facility(current_facility).order(created_at: :desc).paginate(page: params[:page])
      end

      def new
        @submissions = Submission.ready_for_batch.for_facility(current_facility)
      end

      def create
        # Whitelisting should happen in the form object
        if @batch.update_attributes(params[:batch].merge(created_by: current_user, facility: current_facility))
          redirect_to [current_facility, :sanger_sequencing, :admin, :submissions], notice: text("create.success")
        else
          @submissions = Submission.ready_for_batch.for_facility(current_facility)
          flash.now[:alert] = @batch.errors.map { |_k, msg| msg }.to_sentence
          render :new
        end
      end

      def destroy
        @batch.destroy
        redirect_to facility_sanger_sequencing_admin_batches_path, notice: text("destroy.success")
      end

      private

      def load_batch
        @batch = Batch.for_facility(current_facility).find(params[:id])
      end

      def load_batch_form
        @batch = BatchForm.new
      end

    end

  end

end
