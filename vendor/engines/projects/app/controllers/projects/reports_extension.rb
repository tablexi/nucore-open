module Projects

  class ReportsExtension

    def self.general_report
      :project
    end

    def self.instrument_report
      -> (res) do
          [res.product, res.order_detail.project.try(:name)]
      end
    end

  end

end
