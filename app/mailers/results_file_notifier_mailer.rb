# frozen_string_literal: true

class ResultsFileNotifierMailer < ApplicationMailer

  def file_uploaded
    @order_detail = params[:file].order_detail
    mail(to: @order_detail.user.email, subject: text("results_file_notifier_mailer.file_uploaded.subject"))
  end

end
