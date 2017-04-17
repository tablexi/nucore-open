module SecureRooms

  class Occupancy < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id
    belongs_to :user
    belongs_to :account
    belongs_to :entry_event, class_name: SecureRooms::Event
    belongs_to :exit_event, class_name: SecureRooms::Event

    validates :product_id, :user_id, presence: true

    def mark_oprhaned!
      update!(orphan: Time.current)
    end

    def self.valid
      where.not(orphan: nil)
    end

    def self.current
      valid.where(exit_event_id: nil).where.not(entry_event_id: nil)
    end

    def self.recent
      # Either 24h or 10pax
      valid.where.not(exit_event_id: nil).limit(10)
    end

  end

end
