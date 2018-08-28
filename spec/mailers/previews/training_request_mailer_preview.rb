# frozen_string_literal: true

class TrainingRequestMailerPreview < ActionMailer::Preview

  def notify_facility_staff
    # Is not null and not blank. Oracle does not support `where.not(traning_request_contacts: "")` for CLOBS.
    products_with_contacts = Product.requiring_approval.where("LENGTH(training_request_contacts) > 0")
    product = NUCore::Database.random(products_with_contacts)
    user = NUCore::Database.random(User.all)
    TrainingRequestMailer.notify_facility_staff(user, product)
  end

end
