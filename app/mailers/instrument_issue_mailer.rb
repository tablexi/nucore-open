# frozen_string_literal: true

class InstrumentIssueMailer < ApplicationMailer

  def create
    @product = params[:product]
    @user = params[:user]
    @message = params[:message]
    recipients = params[:recipients]
    mail(to: recipients, subject: text("create.subject", product: @product))
  end

  protected

  def translation_scope
    "views.#{self.class.name.underscore}"
  end

end
