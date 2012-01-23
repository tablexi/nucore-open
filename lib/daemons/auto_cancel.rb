require File.expand_path('base', File.dirname(__FILE__))

Daemons::Base.new('auto_cancel').start do
  if NUCore::Database.oracle?
    time_condition=" EXTRACT(MINUTE FROM SYS_EXTRACT_UTC(CURRENT_TIMESTAMP)-reserve_start_at) >= auto_cancel_mins"
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

  cancelable.each do |res|
    begin
      res.update_attributes!(
        :canceled_at => Time.zone.now,
        :canceled_by => 0,
        :canceled_reason => 'reservation was not activated before auto cancel minutes'
      )
    rescue => e
      puts "Could not auto cancel reservation #{res.id}! #{e.message}\n#{e.backtrace.join("\n")}"
    end
  end

  sleep 1.minute
end


