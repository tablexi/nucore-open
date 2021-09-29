# frozen_string_literal: true

module SecureRooms

  module UserExtension

    extend ActiveSupport::Concern

    included do
      validates :card_number, uniqueness: { allow_blank: true }
      validates :i_class_number, uniqueness: { allow_blank: true }
    end

  end

end
