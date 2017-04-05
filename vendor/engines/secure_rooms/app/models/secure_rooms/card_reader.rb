module SecureRooms

  class CardReader < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id

    validates :product_id, :card_reader_number, :control_device_number, presence: true
    validates :card_reader_number, uniqueness: { scope: :control_device_number }

    delegate :facility, to: :secure_room

    alias_attribute :ingress, :direction_in

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

  end

end
