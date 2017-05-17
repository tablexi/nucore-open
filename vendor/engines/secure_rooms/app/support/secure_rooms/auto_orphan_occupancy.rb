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
      OrderDetail.joins(:occupancy).merge(SecureRooms::Occupancy.current)
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
