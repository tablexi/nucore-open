module SecureRooms

  class AutoOrphanOccupancy

    def perform
      occupancy_order_details.each do |od|
        od.transaction do
          orphan_occupancy(od)
        end
      end
    end

    private

    def occupancy_order_details
      OrderDetail.joins(:occupancy).merge(long_running_occupancies)
    end

    def long_running_occupancies
      SecureRooms::Occupancy.current.where(
        SecureRooms::Occupancy.arel_table[:entry_at].lt(Time.current - 12.hours),
      )
    end

    def orphan_occupancy(od)
      od.occupancy.mark_orphaned!
      SecureRooms::AccessHandlers::OrderHandler.process(od.occupancy)
    rescue => e
      ActiveSupport::Notifications.instrument("background_error",
                                              exception: e, information: "Failed orphan occupancy order detail with id: #{od.id}")
      raise ActiveRecord::Rollback
    end

  end

end
