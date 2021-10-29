# frozen_string_literal: true

module SecureRooms

  module UserExtension

    extend ActiveSupport::Concern

    included do
      NULL_ATTRS = %w(card_number i_class_number)

      before_save :nil_if_blank

      validates :card_number, uniqueness: { allow_blank: true, case_sensitive: false }
      validates :i_class_number, uniqueness: { allow_blank: true, case_sensitive: false }

      def self.for_card_number(card_number)
        find_by(card_number: card_number) || find_by(card_number: card_number.split("-").first)
      end

      def nil_if_blank
        NULL_ATTRS.each { |attr| self[attr] = nil if self[attr].blank? }
      end
    end

  end

end
