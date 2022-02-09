# frozen_string_literal: true

class TrainingRequestMailer < ApplicationMailer

  def notify_facility_staff
    @user = params[:user]
    @product = params[:product]
    if @product.training_request_contacts.any?
      mail(to: @product.training_request_contacts, subject: t("training_request_mailer.notify_facility_staff.subject", facility: @product.facility))
    end
  end

end
