module SecureRooms

  class CardReader < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id

    delegate :facility, to: :secure_room

    alias_attribute :ingress, :direction_in

    validates :product_id, :card_reader_number, :control_device_number, presence: true
    validates :card_reader_number, uniqueness: { scope: :control_device_number }
    validates :tablet_token, uniqueness: true

    before_create :set_tablet_token

    def egress?
      !ingress?
    end

    def direction
      I18n.t("human_direction.#{direction_in}", scope: attribute_translation_scope)
    end

    def direction_options
      I18n.t("human_direction", scope: attribute_translation_scope).invert.to_a
    end

    private

    def attribute_translation_scope
      "#{self.class.i18n_scope}.attributes.#{model_name.i18n_key}"
    end

    def set_tablet_token
      return if tablet_token.present?

      # Generate random tokens until it finds one that doesn't already exist
      self.tablet_token = loop do
        token = ("A".."Z").to_a.sample(12).join
        break token if self.class.find_by(tablet_token: token).blank?
      end
    end

  end

end
