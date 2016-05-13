module Projects

  class ReportsExtension

    def self.general_report
      :project
    end

    def self.instrument_report
      -> (reservation) { reservation.order_detail.project }
    end

  end

end
