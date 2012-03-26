require File.expand_path('base', File.dirname(__FILE__))

Daemons::Base.new('auto_cancel').start do
  if NUCore::Database.oracle?
    time_condition=<<-CONDITION
      (EXTRACT(MINUTE FROM (SYS_EXTRACT_UTC(CURRENT_TIMESTAMP) - reserve_start_at)) +
       EXTRACT(HOUR FROM (SYS_EXTRACT_UTC(CURRENT_TIMESTAMP) - reserve_start_at))*60 +
       EXTRACT(DAY FROM (SYS_EXTRACT_UTC(CURRENT_TIMESTAMP) - reserve_start_at))*24*60) >= auto_cancel_mins
    CONDITION
  else
    time_condition=" TIMESTAMPDIFF(MINUTE, reserve_start_at, UTC_TIMESTAMP) >= auto_cancel_mins"
  end

  cancelable=Reservation.joins(:instrument).where(
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
        #{time_condition}
    SQL
  ).readonly(false).all

  # we need something that responds to #id to satisfy OrderDetail#cancel_reservation
  Admin=Struct.new(:id)
  admin=Admin.new
  admin.id=0

  cancelable.each do |res|
    next if res.order_detail.blank?

    begin
      res.order_detail.cancel_reservation admin, OrderStatus.cancelled.first, true
      res.update_attribute :canceled_reason, 'auto cancelled by system'
    rescue => e
      puts "Could not auto cancel reservation #{res.id}! #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end

  sleep 1.minute.to_i
end


