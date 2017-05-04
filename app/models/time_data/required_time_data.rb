module TimeData

  class RequiredTimeData

    def order_completable?
      false
    end

    def problem?
      true
    end

    # Gives us both `blank?` and `present?`
    def blank?
      true
    end

  end

end
