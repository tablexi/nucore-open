module SangerSequencing

  class SubmissionsController < ApplicationController

    def new
      @submission = Submission.where(order_detail_id: params[:receiver_id]).first_or_create
      # TODO: refactor
      if @submission.samples.empty?
        quantity = params[:quantity].to_i
        quantity = 10 if quantity <= 0
        quantity.times { @submission.samples.create! }
      end
    end

  end

end
