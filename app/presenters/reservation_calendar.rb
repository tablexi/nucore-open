class ReservationCalendar < SimpleDelegator

  def self.to_calendar(reservation)
    ReservationCalendar.new(reservation).as_ical
  end

  def as_ical

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(reserve_start_at)
      e.dtend = Icalendar::Values::DateTime.new(reserve_end_at)
      e.summary = "#{facility.abbreviation}: #{product.name}"
      e.description = "#{facility.name} reservation for #{product.name}. Order number #{order.id}"
      e.location = facility.name
      e.ip_class = "PRIVATE"
    end
    cal
  end

end
