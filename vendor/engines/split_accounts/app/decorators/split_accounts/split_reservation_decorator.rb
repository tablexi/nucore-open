module SplitAccounts

  class SplitReservationDecorator < SimpleDelegator

    def duration_mins
      __getobj__.instance_variable_get(:@duration_mins)
    end

    def actual_duration_mins
      __getobj__.instance_variable_get(:@actual_duration_mins)
    end

    # Let it pretend to be a real OrderDetail
    def is_a? klass
      __getobj__.class.object_id == klass.object_id
    end

    def self.primary_key
      Reservation.primary_key
    end

  end

end
