module SecureRooms

  module AccessHandlers

    class OrderHandler

      attr_reader :order, :order_detail, :occupancy

      def self.process(occupancy)
        new(occupancy).process
      end

      def initialize(occupancy)
        @occupancy = occupancy
      end

      def process
        return unless occupancy.account_id?

        find_or_create_order
        fulfill_order if occupancy.complete?

        order
      end

      private

      def find_or_create_order
        if occupancy.order_detail_id?
          @order = order_detail.order
          @order_detail = occupancy.order_detail
        else
          create_order
        end
      end

      def fulfill_order
        order_detail.update_order_status! occupancy.user, OrderStatus.complete.first
      end

      def create_order
        ActiveRecord::Base.transaction do
          create_order_and_detail
          order.validate_order!
          order.purchase!
        end
      end

      def create_order_and_detail
        @order = Order.create!(
          account: occupancy.account,
          user: occupancy.user,
          facility: occupancy.facility,
          created_by_user: occupancy.user,
        )
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
