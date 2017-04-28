module TimeData

  class RequiredTimeData

    def order_completable?
      false
    end

    def blank?
      true
    end

    def completion_problem?
      true
    end

  end

end
