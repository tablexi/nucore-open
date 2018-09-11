class CancellationMailerPreview < ActionMailer::Preview

  def notify_facility
    products_with_contacts = Product.where("LENGTH(cancellation_email_recipients) > 0")
    product = NUCore::Database.random(products_with_contacts)
    CancellationMailer.notify_facility(NUCore::Database.random(product.order_details.canceled))
  end

end
