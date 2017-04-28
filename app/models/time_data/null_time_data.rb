module TimeData

  class NullTimeData

    def order_completable?
      true
    end

    def problem?
      false
    end

    # Gives us both `blank?` and `present?`
    def blank?
      true
    end

  end

end
