class ReservationCalendar < SimpleDelegator

  attr_accessor :hostname, :ical, :protocol

  def self.to_calendar(reservation, hostname, protocol)
    new(reservation, hostname, protocol).as_ical
  end

  def initialize(reservation, hostname, protocol)
    super(reservation)
    @hostname = hostname
    @protocol = protocol
    generate_ical
  end

  def generate_ical
    @ical = Icalendar::Calendar.new
    ical.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(reserve_start_at)
      e.dtend = Icalendar::Values::DateTime.new(reserve_end_at)
      e.summary = summary
      e.description = description
      e.location = facility.name
      e.url = url
      e.ip_class = "PRIVATE"
    end
    ical
  end

  def to_ical
    ical.publish
    ical.to_ical
  end

  def summary
    I18n.t("ical.summary", facility: facility.abbreviation, product: product.name)
  end

  def description
    I18n.t(
      "ical.description",
      facility: facility.name,
      product: product.name,
      order_number: order_detail.order_number)
  end

  def url
    Icalendar::Values::Uri.new(
      Rails.application.routes.url_helpers.order_order_detail_url(
        order_id: order.id,
        id: order_detail.id,
        host: @hostname,
        protocol: protocol))
  end

end
