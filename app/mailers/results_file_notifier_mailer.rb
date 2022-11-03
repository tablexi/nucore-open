# frozen_string_literal: true

class ResultsFileNotifierMailer < ApplicationMailer

  def file_uploaded(file)
    @order_detail = file.order_detail
    reply_to = SettingsHelper.setting("email.results_file_notifier.reply_to") || SettingsHelper.setting("email.from")
    mail(reply_to: reply_to, to: @order_detail.user.email, subject: text("results_file_notifier_mailer.file_uploaded.subject"))
  end

end
