class TrainingRequestMailerPreview < ActionMailer::Preview

  def notify_facility_staff
    product = NUCore::Database.random(Product.requiring_approval.where.not(training_request_contacts: [nil, ""]))
    user = NUCore::Database.random(User.all)
    TrainingRequestMailer.notify_facility_staff(user, product)
  end

end
