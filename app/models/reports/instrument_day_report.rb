class Reports::InstrumentDayReport
  def initialize(reservations)
    @reservations = reservations
  end

  def build_report(&report_on)
    @data = {}
    @totals = DataRow.new
    @reservations.each do |reservation|
      data_value = yield reservation
      @data[reservation.product.name] ||= DataRow.new
      @data[reservation.product.name].add(data_value)
      @totals.add(data_value)
    end
  end

  def rows
    @data.sort.map do |key, data_row|
      [key] + data_row
    end
  end

  def totals
    @totals.to_ary
  end

  class DataRow
    def initialize(*args)
      @data = [0,0,0,0,0,0,0]
    end

    def add(new_data)
      @report_type = new_data

      @data[new_data.day] += new_data.value
    end

    def to_ary
      @data.map { |value| @report_type.transform(value) }
    end
  end

  class DayValue
    def initialize(reservation)
      @reservation = reservation
    end

    def day; raise "Subclass must implement"; end
    def value; raise "Subclass must implement"; end

    def transform(data)
      data
    end
  end

  class ReservedQuantity < DayValue
    def day; @reservation.reserve_start_at.wday; end
    def value; 1 end
  end

  class ReservedHours < DayValue
    include ReportsHelper

    def day; @reservation.reserve_start_at.wday; end
    def value; @reservation.duration_mins; end

    def transform(data)
      to_hours(data, 1)
    end
  end

  class ActualHours < DayValue
    include ReportsHelper
    def day; @reservation.reserve_start_at.try(:wday) || 0; end
    def value; @reservation.actual_start_at.present? ? @reservation.duration_mins : 0; end

    def transform(data)
      to_hours(data, 1)
    end
  end

  class ActualQuantity < DayValue
    def day; @reservation.actual_start_at.try(:wday) || 0; end
    def value; @reservation.actual_start_at.present? ? 1 : 0; end
  end



end
