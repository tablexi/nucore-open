# frozen_string_literal: true

module Projects

  class ReportsExtension

    def self.general_report
      ->(order_detail) { order_detail.project || " No Project" }
    end

    def self.instrument_report
      ->(reservation) { reservation.order_detail.project || " No Project" }
    end

  end

end
