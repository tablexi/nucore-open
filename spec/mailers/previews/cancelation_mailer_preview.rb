# frozen_string_literal: true

class CancellationMailerPreview < ActionMailer::Preview

  def notify_facility
    products_with_contacts = Product.where("LENGTH(cancellation_email_recipients) > 0")
    product = Nucore::Database.random(products_with_contacts)
    CancellationMailer.with(order_detail: Nucore::Database.random(product.order_details.canceled)).notify_facility
  end

end
