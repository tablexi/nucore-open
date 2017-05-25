module SecureRooms

  class AutoOrphanOccupancy

    def perform
      long_running_occupancies.each do |occupancy|
        occupancy.transaction do
          orphan_occupancy(occupancy)
        end
      end
    end

    private

    def long_running_occupancies
      SecureRooms::Occupancy.current.where("entry_at < ?", 12.hours.ago)
    end

    def orphan_occupancy(occupancy)
      occupancy.mark_orphaned!
      SecureRooms::AccessHandlers::OrderHandler.process(occupancy)
    rescue => e
      ActiveSupport::Notifications.instrument("background_error",
                                              exception: e, information: "Failed orphan occupancy order detail with id: #{od.id}")
      raise ActiveRecord::Rollback
    end

  end

end
