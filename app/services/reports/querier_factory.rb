module Reports

  class QuerierFactory

    @@klass = Settings.reports.querier.constantize

    def self.instance(*args)
      @@klass.new(*args)
    end

  end

end
