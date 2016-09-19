module BulkEmail

  class DeliveryForm

    include ActiveModel::Model

    attr_accessor :subject, :custom_message, :recipient_ids
    attr_reader :facility

    validates :subject, :custom_message, :recipient_ids, presence: true

    def initialize(facility)
      @facility = facility
    end

    def assign_attributes(params)
      params ||= {}
      @custom_message = params[:custom_message]
      @recipient_ids = params[:recipient_ids]
      @subject = params[:subject]
    end

    def deliver_all
      recipients.each { |recipient| deliver(recipient) } if valid?
    end

    private

    def deliver(recipient)
      Mailer.send_mail(
        recipient: recipient,
        subject: subject,
        facility: facility,
        custom_message: custom_message,
      ).deliver_later
    end

    def recipients
      @recipients ||= User.where_ids_in(recipient_ids)
    end

  end

end
