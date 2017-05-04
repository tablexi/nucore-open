module SecureRooms

  module AccessHandlers

    class OrderHandler

      attr_reader :occupancy, :order, :order_detail

      def self.process(occupancy)
        new(occupancy).process
      end

      def initialize(occupancy)
        @occupancy = occupancy
      end

      def process
        ActiveRecord::Base.transaction do
          create_order
          create_order_detail

          if occupancy.account_id?
            order.validate_order!
            order.purchase!
          end
        end

        order
      end

      private

      def create_order
        @order = Order.create!(
          account: occupancy.account,
          user: occupancy.user,
          facility: occupancy.facility,
          created_by_user: occupancy.user,
        )
      end

      def create_order_detail
        @order_detail = order.order_details.create!(
          account: occupancy.account,
          product: occupancy.secure_room,
          occupancy: occupancy,
          created_by_user: occupancy.user,
          quantity: 1,
        )
      end

    end

  end

end
