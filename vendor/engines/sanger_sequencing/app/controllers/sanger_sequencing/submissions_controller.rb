module SangerSequencing

  class SubmissionsController < ApplicationController

    load_resource only: [:edit, :update]

    def new
      order_detail = SangerSequencing::OrderDetail.find(params[:receiver_id])
      @submission = Submission.where(order_detail_id: order_detail.id).first_or_create
      # TODO: refactor
      if @submission.samples.empty?
        quantity = params[:quantity].to_i
        quantity = 10 if quantity <= 0
        quantity.times { @submission.samples.create! }
      end
    end

    def edit
      render :new
    end

    def update
      @order_detail = SangerSequencing::OrderDetail.find(@submission.order_detail_id)
      if SubmissionUpdater.new(@submission).update_attributes(submission_params)
        redirect_to "#{params[:success_url]}&#{external_return_options.to_query}"
      else
        flash.now[:alert] = @submission.errors.messages.values.join(". ")
        render :new
      end
    end

    private

    def submission_params
      params.require(:sanger_sequencing_submission).permit(samples_attributes: [:id, :customer_sample_id])
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
