module SecureRooms

  class Occupancy < ActiveRecord::Base

    include DateTimeInput::Model

    belongs_to :secure_room, foreign_key: :product_id
    belongs_to :user
    belongs_to :account
    belongs_to :order_detail
    belongs_to :entry_event, class_name: SecureRooms::Event
    belongs_to :exit_event, class_name: SecureRooms::Event

    delegate :facility, to: :secure_room
    delegate :to_s, to: :range

    date_time_inputable :entry_at
    date_time_inputable :exit_at

    alias_attribute :actual_start_at, :entry_at
    alias_attribute :actual_end_at, :exit_at

    validates :secure_room, :user, presence: true

    def self.valid
      where(orphaned_at: nil)
    end

    def self.orphaned
      where.not(orphaned_at: nil)
    end

    def self.current
      valid.where(exit_at: nil).where.not(entry_at: nil)
    end

    def self.recent
      valid.where.not(exit_at: nil).limit(10)
    end

    def mark_orphaned!
      update!(orphaned_at: Time.current)
    end

    def orphan?
      orphaned_at?
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

    def order_completable?
      activity_finalized = orphaned_at? || (entry_at && exit_at)
      order_detail_id? && account_id? && activity_finalized
    end

    def actual_duration_mins
      range.duration_mins
    end

    def problem_description_key
      if entry_at.blank?
        :missing_entry
      elsif exit_at.blank?
        :missing_exit
      end
    end

    private

    def range
      TimeRange.new(entry_at, exit_at)
    end

  end

end
