module SecureRooms

  class Occupancy < ActiveRecord::Base

    belongs_to :secure_room, foreign_key: :product_id
    belongs_to :user
    belongs_to :account
    belongs_to :order_detail
    belongs_to :entry_event, class_name: SecureRooms::Event
    belongs_to :exit_event, class_name: SecureRooms::Event

    validates :secure_room, :user, presence: true

    delegate :facility, to: :secure_room
    delegate :order, to: :order_detail

    def self.valid
      where(orphaned_at: nil)
    end

    def self.orphaned
      where.not(orphaned_at: nil)
    end

    def self.current
      valid.where(exit_event_id: nil).where.not(entry_event_id: nil)
    end

    def self.recent
      valid.where.not(exit_event_id: nil).limit(10)
    end

    def mark_orphaned!
      update!(orphaned_at: Time.current)
    end

    def orphan?
      orphaned_at?
    end

    def complete?
      entry_at && exit_at
    end

    def associate_entry!(event)
      update!(
        entry_event: event,
        entry_at: Time.current,
      )
      self
    end

    def associate_exit!(event)
      update!(
        exit_event: event,
        exit_at: Time.current,
      )
      self
    end

  end

end
