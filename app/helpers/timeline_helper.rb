module TimelineHelper
  def reservation_classes(reservation, classes=nil)
    classes = ['unit']
    classes << 'tip' unless reservation.blackout?
    classes << 'blackout' if reservation.blackout?
    classes << 'admin' if reservation.admin?
    classes << 'behalf_of' if reservation.ordered_on_behalf_of?
    classes << 'in_progress' if reservation.can_switch_instrument?
    classes << "status_#{reservation.order_detail.order_status.to_s.downcase}" if reservation.order_detail
    classes << spans_midnight_class(reservation.reserve_start_at, reservation.reserve_end_at)
    classes.join(" ")
  end

  MINUTE_TO_PIXEL_RATIO = 0.6
  def datetime_left_position(display_date, datetime)
    # don't start before midnight of the display_date
    time_to_use = [datetime, display_date.beginning_of_day].max

    "#{((time_to_use - display_date.beginning_of_day) / 60 * MINUTE_TO_PIXEL_RATIO).floor}px"
  end

  def datetime_width(display_date, datetime_start, datetime_end)
    # cut off the beginning if it starts before midnight
    start_datetime_to_use = [datetime_start, display_date.beginning_of_day].max
    
    # cut it off at midnight of start day if end time goes into the next day
    end_datetime_to_use = [datetime_end, display_date.end_of_day].min
    # In Ruby 1.8.7, the subtraction leads to a .99999 value, so go ahead and round that off
    "#{((end_datetime_to_use - start_datetime_to_use).round(4) / 60 * MINUTE_TO_PIXEL_RATIO).floor}px"
  end

  def reservation_width(display_date, reservation)
    datetime_width(display_date, reservation.display_start_at, reservation.display_end_at)
  end

  def reservation_left_position(display_date, reservation)
    datetime_left_position(display_date, reservation.display_start_at)
  end
  
  def spans_midnight_class(datetime_start, datetime_end)
    return 'spans_into_tomorrow' if datetime_end > @display_date.end_of_day
    return 'spans_into_yesterday' if datetime_start < @display_date.beginning_of_day
    return nil
  end
end