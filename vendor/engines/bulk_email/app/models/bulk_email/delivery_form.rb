module BulkEmail

  class DeliveryForm

    include ActiveModel::Validations

    attr_accessor :subject, :custom_message, :recipient_ids

    validates :subject, :custom_message, :recipient_ids, presence: true

    def deliver_all!
      recipients.each { |recipient| deliver!(recipient.email) }
    end

    private

    def deliver!(email)
      Mailer.mail(to: email, subject: subject).deliver_later
    end

    def recipients
      @recipients ||= User.where_ids_in(recipient_ids)
    end

  end

end
