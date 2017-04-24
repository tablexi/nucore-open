module SecureRooms

  module AccessHandlers

    class OrderHandler

      def self.process(occupancy)
        return unless occupancy.account_id?

        order = Order.create!(
          account: occupancy.account,
          user: occupancy.user,
          facility: occupancy.facility,
          created_by_user: occupancy.user,
        )

        order.order_details.create!(
          account: occupancy.account,
          product: occupancy.secure_room,
          occupancy: occupancy,
          created_by_user: occupancy.user,
          quantity: 1,
        )

        order.validate_order!
        order.purchase!

        order
      end

    end

  end

end
