module SangerSequencing

  module Admin

    class BatchesController < AdminController

      admin_tab :all
      layout "two_column", only: [:index]
      before_action { @active_tab = "admin_sanger_sequencing" }
      before_action :load_batch_form, only: [:new, :create]
      before_action :load_batch, only: [:well_plate, :show, :destroy, :upload]
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
          redirect_to [current_facility, :sanger_sequencing, :admin, :batches], notice: text("create.success")
        else
          @submissions = Submission.ready_for_batch.for_facility(current_facility)
          flash.now[:alert] = @batch.errors.map { |_k, msg| msg }.to_sentence
          render :new
        end
      end

      def show
        @submissions = @batch.submissions.purchased # purchased to get the same sorting
      end

      def well_plate
        index = params[:well_plate_index].to_i
        @well_plate = @batch.well_plates[index - 1]
        raise ActiveRecord::RecordNotFound unless @well_plate

        respond_to do |format|
          format.csv do
            render csv: WellPlatePresenter.new(@well_plate), filename: "well_plate_#{@batch.id}_#{index}"
          end
        end
      end

      def destroy
        @batch.destroy
        redirect_to facility_sanger_sequencing_admin_batches_path, notice: text("destroy.success")
      end

      def upload
        response = begin
          params[:qqfilename] =~ /\A(\d+).+/
          raise UploadError, "Filename should begin with the sample ID, e.g. 43212_B01_001.seq" unless $1.present?

          sample = @batch.samples.find_by(id: $1)
          raise UploadError, "Could not find sample #{$1} in this batch" unless sample

          file = StoredFile.new(file: params[:qqfile], name: params[:qqfilename],
            file_type: "sample_result", created_by: current_user.id,
            order_detail: sample.submission.order_detail)

          if file.save
            { success: true }
          else
            raise UploadError, file.errors.full_messages
          end

        rescue UploadError => e
          { success: false, error: e.message }
        end

        respond_to do |format|
          format.json { render json: response }
        end
      end

      class UploadError < StandardError
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
