# frozen_string_literal: true

class InstrumentIssueMailer < BaseMailer

  def create(product:, user:, message:)
    @product = product
    @user = user
    @message = message
    mail(to: to_notify.uniq, subject: text("create.subject", product: product))
  end

  protected

  def translation_scope
    "views.#{self.class.name.underscore}"
  end

  def to_notify
    # #137686 NU did not specify sending to the facility contact email: @product.email
    @product.facility.director_and_admins.pluck(:email) + @product.training_request_contacts
  end

end
