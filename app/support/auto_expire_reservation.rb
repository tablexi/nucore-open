# frozen_string_literal: true

class AutoExpireReservation

  def perform
    order_details.each do |od|
      od.transaction do
        expire_reservation(od)
      end
    end
  end

  private

  def order_details
    purchased_active_order_details
  end

  def earliest_allowed_time
    Settings.reservations.timeout_period.seconds.ago
  end

  def purchased_active_order_details
    OrderDetail.purchased_active_reservations
               .joins(:product)
               .joins_relay
               .where("reservations.reserve_end_at < ?", earliest_allowed_time)
               .readonly(false)
  end

  def expire_reservation(od)
    od.complete!

    # OrderDetail#complete! sets fulfilled_at and price policy,
    # so we have to reset them.
    od.fulfilled_at = od.reservation.reserve_end_at
    od.save!
  rescue => e
    ActiveSupport::Notifications.instrument("background_error",
                                            exception: e, information: "Failed expire reservation order detail with id: #{od.id}")
    raise ActiveRecord::Rollback
  end

end
