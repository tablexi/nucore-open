module SplitAccounts

  class SplitReservationDecorator < SimpleDelegator

    def duration_mins
      __getobj__.instance_variable_get(:@duration_mins)
    end

    def actual_duration_mins
      __getobj__.instance_variable_get(:@actual_duration_mins)
    end

    # If we don't override this, then it tries to set the inverse_of, which errors
    def order_detail=(order_detail)
      @order_detail = order_detail
    end

    def order_detail
      @order_detail || __getobj__.order_detail
    end

    # Let it pretend to be a real Reservation
    def is_a? klass
      __getobj__.class.object_id == klass.object_id
    end

    def self.primary_key
      Reservation.primary_key
    end

  end

end
