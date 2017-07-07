class ReservationCalendar < SimpleDelegator

  attr_accessor :hostname

  def self.to_calendar(reservation, hostname)
    new(reservation, hostname).as_ical
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
      e.summary = I18n.t(
        "ical.summary", facility: facility.abbreviation, product: product.name)
      e.description = I18n.t(
        "ical.description",
        facility: facility.name,
        product: product.name,
        order_number: order_detail.order_number)
      e.location = facility.name
      e.url = Icalendar::Values::Uri.new(
        Rails.application.routes.url_helpers.order_order_detail_url(
          order_id: order.id,
          id: order_detail.id,
          host: @hostname))
      e.ip_class = "PRIVATE"
    end
    cal
  end

end
