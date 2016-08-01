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
      @rows ||= raw_values.map do |row|
        row[:hours] = format("%.2f", row.delete(:seconds) / 3600.0).to_f
        row
      end.map(&:values)
    end

    def total_hours
      rows.map { |row| row[HOURS_INDEX] }.sum
    end

    def total_quantity
      rows.map { |row| row[QUANTITY_INDEX] }.sum
    end

    private

    def raw_values
      query.each_with_object({}) do |row, report|
        key = "#{row.product_id}/#{row.type}/#{row.category}"
        report[key] ||= row_to_h(row)
        report[key][:quantity] += 1
        report[key][:seconds] += row_duration_in_seconds(row)
      end.values
    end

    def row_duration_in_seconds(row)
      reserve_end_at = row.reserve_end_at || end_time
      reserve_end_at = end_time if reserve_end_at > end_time
      reserve_start_at = row.reserve_start_at > start_time ? row.reserve_start_at : start_time
      reserve_end_at - reserve_start_at
    end

    def row_to_h(row)
      {
        instrument_name: row.product.name,
        type: row.type.to_s.sub(/Reservation\z/, ""),
        category: reservation_category_label(row.category),
        quantity: 0,
        seconds: 0,
      }
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
