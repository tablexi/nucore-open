class ReservationCalendar < SimpleDelegator

  def initialize(reservation)
    super(reservation)
  end

  def as_ical
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(reserve_start_at)
      e.dtend = Icalendar::Values::DateTime.new(reserve_end_at)
      e.summary = "Reservation for #{product.name}"
      e.description = "Reservation for #{product.name}"
      e.ip_class = "PRIVATE"
    end
    cal
  end

end
