class ReservationCalendar < SimpleDelegator

  attr_accessor :hostname

  def self.to_calendar(reservation)
    ReservationCalendar.new(reservation).as_ical
  end

  def initialize(reservation, hostname)
    super(reservation)
    @hostname = hostname
  end

  def as_ical
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(reserve_start_at)
      e.dtend = Icalendar::Values::DateTime.new(reserve_end_at)
      e.summary = "#{facility.abbreviation}: #{product.name}"
      e.description = "#{facility.name} reservation for #{product.name}. Order number #{order.id}"
      e.location = facility.name
      e.url = Icalendar::Values::Uri.new(
        Rails.application.routes.url_helpers.order_order_detail_reservation_url(
          order_id: order.id, order_detail_id: order_detail_id,
          id: id, host: @hostname))
      e.ip_class = "PRIVATE"
    end
    cal
  end

end
