module BulkEmail

  class DeliveryForm

    include ActiveModel::Model

    attr_accessor :custom_subject, :custom_message, :recipient_ids, :product_id, :search_criteria
    attr_reader :facility, :user

    validates :custom_subject, :custom_message, :recipient_ids, presence: true

    def initialize(user, facility)
      @user = user
      @facility = facility
    end

    def assign_attributes(params)
      params ||= {}
      @custom_message = params[:custom_message]
      @custom_subject = params[:custom_subject]
      @recipient_ids = params[:recipient_ids]
      @product_id = params[:product_id]
      @search_criteria = parse_json_hash(params[:search_criteria])
    end

    def deliver_all
      if valid?
        BulkEmail::Job.transaction do
          recipients.each { |recipient| deliver(recipient) }
          record_delivery
        end
      end
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

    def record_delivery
      BulkEmail::Job.create!(
        facility: facility,
        user: user,
        subject: custom_subject,
        body: custom_message,
        recipients: recipients.map(&:email),
        search_criteria: search_criteria,
      )
    end

    def product
      Product.find(product_id) if product_id.present?
    end

    def parse_json_hash(string)
      hash = JSON.parse(string.presence || "{}")
      hash.is_a?(Hash) ? hash : {}
    rescue JSON::ParserError, TypeError
      {}
    end

  end

end
