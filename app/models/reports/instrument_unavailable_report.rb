module Reports

  class InstrumentUnavailableReport

    QUANTITY_INDEX = 3
    HOURS_INDEX = 4

    attr_reader :facility, :start_time, :end_time

    include FacilityReservationsHelper

    def initialize(facility, date_start, date_end)
      @facility = facility
      @start_time = date_start.beginning_of_day
      @end_time = date_end.end_of_day
    end

    def numeric_columns
      [QUANTITY_INDEX, HOURS_INDEX]
    end

    def rows
      @rows ||= grouped_query.map do |key, reservations|
        key +
          [
            reservations.count,
            as_hours(reservations_total_seconds(reservations)),
          ]
      end
    end

    def total_hours
      format("%.2f", rows.map { |row| BigDecimal.new(row[HOURS_INDEX]) }.sum)
    end

    def total_quantity
      rows.map { |row| row[QUANTITY_INDEX] }.sum
    end

    private

    def as_hours(seconds)
      format("%.2f", (seconds / 3600.0))
    end

    def grouped_query
      @grouped_query ||= query.group_by do |res|
        [
          res.product.name,
          res.type.to_s.sub(/Reservation\z/, ""),
          reservation_category_label(res.category),
        ]
      end
    end

    def reservations_total_seconds(reservations)
      reservations.inject(0) do |sum, r|
        sum + row_duration_in_seconds(r)
      end
    end

    # If a reservation begins and ends within the bounds of the report, then
    # the duration should be the same as the reservation duration.
    #
    # But if a reservation began before the report start, or ends after the
    # report end, or has not ended, this should only count the part of the
    # reservation that falls within the report bounds.
    #
    # Examples with a report range of Jan 1 to 3 (259,200 seconds, or 3 days):
    #
    # * A reservation that began December 31 at noon and has not ended
    #   - The duration is 259,200 seconds (the entire report range; 3 days)
    #
    # * A reservation that began December 31 at noon and ended Jan 1 at noon
    #   - The duration is 43,200 seconds (Jan 1 midnight to noon; 12 hours)
    #
    # * A reservation that began Jan 2 at noon and has not ended
    #   - The duration is 129,600 seconds (Jan 1 noon to EOD Jan 3; 36 hours)
    #
    # * A reservation that began Jan 2 at noon and ended Jan 2 at 1:00 pm
    #   - The duration is 3600 seconds (1 hour)
    def row_duration_in_seconds(row)
      reserve_end_at = row.reserve_end_at || end_time
      reserve_end_at = end_time if reserve_end_at > end_time
      reserve_start_at = row.reserve_start_at > start_time ? row.reserve_start_at : start_time
      reserve_end_at - reserve_start_at
    end

    def query
      @query ||=
        Reservation
        .non_user
        .joins(:product)
        .where("products.facility_id" => facility.id)
        .where("reserve_start_at <= ?", end_time)
        .where("reserve_end_at IS NULL OR reserve_end_at >= ?", start_time)
    end

  end

end
