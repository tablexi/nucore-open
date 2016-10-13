module BulkEmail

  class DeliveryForm

    include ActiveModel::Model

    attr_accessor :custom_subject, :custom_message, :recipient_ids, :product_id
    attr_reader :facility

    validates :custom_subject, :custom_message, :recipient_ids, presence: true

    def initialize(facility)
      @facility = facility
    end

    def assign_attributes(params)
      params ||= {}
      @custom_message = params[:custom_message]
      @custom_subject = params[:custom_subject]
      @recipient_ids = params[:recipient_ids]
      @product_id = params[:product_id]
    end

    def deliver_all
      recipients.each { |recipient| deliver(recipient) } if valid?
    end

    private

    def deliver(recipient)
      Mailer.send_mail(
        recipient: recipient,
        custom_subject: custom_subject,
        facility: facility,
        custom_message: custom_message,
        product: product,
      ).deliver_later
    end

    def recipients
      @recipients ||= User.where_ids_in(recipient_ids)
    end

    def product
      Product.find(product_id) if product_id.present?
    end

  end

end
