module TimeData

  class NullTimeData

    def completion_problem?
      false
    end

    def order_completable?
      true
    end

    # Gives us both `blank?` and `present?`
    def blank?
      true
    end

  end

end
