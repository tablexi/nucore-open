require "csv"

module Reports

  class InstrumentUnavailableExportRaw

    attr_reader :facility, :date_start, :date_end

    include CsvExporter
    include FacilityReservationsHelper

    def initialize(facility:, date_start:, date_end:)
      @facility = facility
      @date_start = date_start
      @date_end = date_end
    end

    def description
      "#{facility.name} Instrument Down Export Raw, #{formatted_date_range}"
    end

    def translation_scope
      "controllers.instrument_unavailable_reports_controller"
    end

    private

    def formatted_total_minutes(reservation)
      start_time = if reservation.reserve_start_at < date_start.beginning_of_day
                     date_start.beginning_of_day
                   else
                     reservation.reserve_start_at
                   end

      end_time = if reservation.reserve_end_at.blank? || (reservation.reserve_end_at > date_end.end_of_day)
                   date_end.end_of_day
                 else
                   reservation.reserve_end_at
                 end

      format("%.2f", (end_time - start_time) / 60.0)
    end

    def default_report_hash
      {
        type: -> (reservation) { reservation.type.sub(/Reservation\z/, "") },
        instrument: -> (reservation) { reservation.product.name },
        start_time: :reserve_start_at,
        end_time: :reserve_end_at,
        total_minutes: -> (reservation) { formatted_total_minutes(reservation) },
        admin_note: :admin_note,
        category: -> (reservation) { reservation_category_label(reservation.category) },
      }
    end

    def reservation_row(reservation)
      report_hash.values.map do |callable|
        result = if callable.is_a?(Symbol)
                   reservation.public_send(callable)
                 else
                   callable.call(reservation)
        end

        if result.is_a?(DateTime)
          format_usa_datetime(result)
        else
          result
        end
      end
    rescue => e
      ["*** ERROR WHEN REPORTING ON RESERVATION #{reservation.id}: #{e.message} ***"]
    end

    def csv_body
      CSV.generate do |csv|
        report_data.each do |reservation|
          csv << reservation_row(reservation)
        end
      end
    end

    def report_data_query
      querier.reservations
    end

    private

    def querier
      @querier ||=
        AdminReservationQuerier.new(facility: @facility,
                                    start_time: date_start.beginning_of_day,
                                    end_time: date_end.end_of_day)
    end

  end

end
