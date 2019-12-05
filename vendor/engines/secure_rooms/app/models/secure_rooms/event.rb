# frozen_string_literal: true

module SecureRooms

  class Event < ApplicationRecord

    belongs_to :secure_room, foreign_key: :product_id, optional: true
    belongs_to :account, optional: true
    belongs_to :card_reader, optional: true
    belongs_to :user, optional: true

    validates :card_reader, :occurred_at, :outcome, presence: true

    delegate :direction, :secure_room, :ingress?, :egress?, to: :card_reader

    def success?
      outcome == "grant"
    end

  end

end
