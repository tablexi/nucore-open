module SecureRooms

  module AccessHandlers

    class OrderHandler

      def self.process(occupancy)
        return unless occupancy.orderable?

        order = Order.create!(
          account: occupancy.account,
          user: occupancy.user,
          facility: occupancy.facility,
          created_by_user: occupancy.user,
        )

        order.order_details.create!(
          product: occupancy.secure_room,
          created_by_user: occupancy.user,
          quantity: 1,
        )

        order
      end

    end

  end

end
