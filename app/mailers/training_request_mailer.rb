class TrainingRequestMailer < BaseMailer

  def notify_facility_staff(user_id, product_id)
    @user = User.find(user_id)
    @product = Product.find(product_id)

    if @product.training_request_contacts.any?
      mail(to: @product.training_request_contacts, subject: t("training_request_mailer.notify_facility_staff.subject", facility: @product.facility))
    end
  end

end
