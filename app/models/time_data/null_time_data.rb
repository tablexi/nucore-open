module TimeData

  class NullTimeData

    def order_completable?
      true
    end

    def problem?
      false
    end

    def problem_description_key
    end

    # Gives us both `blank?` and `present?`
    def blank?
      true
    end

  end

end
