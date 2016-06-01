module SangerSequencing

  class SubmissionsController < ApplicationController
    NEW_IDS_COUNT = 5

    load_resource only: [:edit, :update, :fetch_ids]

    def new
      order_detail = SangerSequencing::OrderDetail.find(params[:receiver_id])
      @submission = Submission.where(order_detail_id: order_detail.id).first_or_create
      clean_samples
      @submission.create_samples!(params[:quantity]) if @submission.samples.empty?
      render :edit
    end

    def edit
      clean_samples
    end

    def update
      @order_detail = SangerSequencing::OrderDetail.find(@submission.order_detail_id)
      if SubmissionUpdater.new(@submission).update_attributes(submission_params)
        redirect_to "#{params[:success_url]}&#{external_return_options.to_query}"
      else
        flash.now[:alert] = @submission.errors.messages.values.join(". ")
        render :edit
      end
    end

    def fetch_ids
      new_samples = @submission.create_samples!(NEW_IDS_COUNT)
      render json: new_samples.map { |s| { id: s.id, customer_sample_id: s.form_customer_sample_id } }
    end

    private

    def clean_samples
      # Clean up from abandoned submissions that might have requested extra IDs
      @submission.samples.where(customer_sample_id: nil).delete_all
    end

    def submission_params
      params.require(:sanger_sequencing_submission)
        .permit(samples_attributes: [:id, :customer_sample_id, :_destroy])
    end

    def external_return_options
      {
        quantity: @submission.samples.count,
        survey_edit_url: edit_sanger_sequencing_submission_url(@submission),
        survey_id: @submission.id,
        survey_url: sanger_sequencing_submission_url(@submission),
        referer: @order_detail.cart_path,
      }
    end

  end

end
