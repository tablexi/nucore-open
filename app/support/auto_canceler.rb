class AutoCanceler

  AdminStruct = Struct.new(:id)

  def cancel_reservations
    return if cancelable_reservations.none?
    cancelable_reservations.each do |res|
      next if res.order_detail.blank?
      cancel_reservation(res)
    end
  end

  def cancelable_reservations
    @cancelable_reservations ||= Reservation
                                 .joins(:product, order_detail: :order)
                                 .where(build_sql, now: Time.zone.now)
                                 .merge(Order.purchased)
                                 .readonly(false)
  end

  def cancel_reservation(res)
    res.order_detail.cancel_reservation(admin, admin: true, admin_with_cancel_fee: true)
    res.update_attribute :canceled_reason, "auto canceled by system"
  rescue => e
    puts "Could not auto cancel reservation #{res.id}! #{e.message}\n#{e.backtrace.join("\n")}"
  end

  private

  def time_condition
    if NUCore::Database.oracle?
      "(:now - reserve_start_At) >= NumToDSInterval(auto_cancel_mins, 'MINUTE')"
    else
      "TIMESTAMPDIFF(MINUTE, reserve_start_at, :now) >= auto_cancel_mins"
    end
  end

  def build_sql
    <<-SQL
        actual_start_at IS NULL
      AND
        actual_end_at IS NULL
      AND
        canceled_at IS NULL
      AND
        auto_cancel_mins IS NOT NULL
      AND
        auto_cancel_mins > 0
      AND
        (order_details.state = 'new' OR order_details.state = 'inprocess')
      AND
        #{time_condition}
    SQL
  end

  def admin
    # we need something that responds to #id to satisfy OrderDetail#cancel_reservation
    admin = AdminStruct.new
    admin.id = 0
    admin
  end

end
