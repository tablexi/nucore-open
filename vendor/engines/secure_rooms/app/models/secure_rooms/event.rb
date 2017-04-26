module SecureRooms

  class Event < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id
    belongs_to :account
    belongs_to :card_reader
    belongs_to :user

    validates :card_reader, :user, :occurred_at, :outcome, presence: true

    delegate :direction, :secure_room, :ingress?, :egress?, to: :card_reader

  end

end
