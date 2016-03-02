module Reports

  class TransformerFactory

    @@klass = Settings.reports.transformer.constantize

    def self.instance(*args)
      @@klass.new(*args)
    end

  end

end
