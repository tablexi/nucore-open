module TimeData

  class SecureRoomPresenter < BasePresenter

    delegate :to_s, :duration_mins, to: :range

    def initialize(order_detail)
      super(order_detail.occupancy)
    end

    private

    def range
      TimeRange.new(entry_at, exit_at)
    end

  end

end
