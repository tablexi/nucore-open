class Reports::InstrumentUtilizationReport
  attr_accessor :key_length
  def initialize(reservations)
    @reservations = reservations
  end

  def build_report(&report_block)
    @data = {}
    @totals = DataRow.new(0, 0, 0)
    @reservations.each do |reservation|
      key = yield reservation
      @key_length = key.length
      add_reservation(key, reservation)
    end
  end

  def rows
    @data.sort.map do |key, data_row|
      key + data_row.row_with_percents(@totals)
    end
  end

  def totals
    @totals.row_with_percents(@totals)
  end

  def add_reservation(key, reservation)
    @data[key] ||= DataRow.new(0, 0, 0)
    data_row = DataRow.new(1, reservation.duration_mins, reservation.actual_duration_mins)
    @data[key] += data_row
    @totals += data_row
  end

  class DataRow
    include ReportsHelper
    attr_accessor :quantity, :reserved_mins, :actual_mins
    def initialize(quantity, reserved_mins, actual_mins)
      @quantity = quantity
      @reserved_mins = reserved_mins
      @actual_mins = actual_mins
    end

    def +(other)
      DataRow.new(self.quantity + other.quantity,
                  self.reserved_mins + other.reserved_mins,
                  self.actual_mins + other.actual_mins)
    end

    def /(other)
      DataRow.new(to_percent(safe_divide(self.quantity, other.quantity)),
                  to_percent(safe_divide(self.reserved_mins, other.reserved_mins)),
                  to_percent(safe_divide(self.actual_mins, other.actual_mins.to_f)))
    end

    def safe_divide(a, b)
      return 0 if b == 0
      a.to_f / b.to_f
    end

    def row_with_percents(totals)
      percent = self / totals
      [quantity,
        to_hours(reserved_mins, 1),
        format_percent(percent.reserved_mins),
        to_hours(actual_mins, 1),
        format_percent(percent.actual_mins)]
    end
  end
end
