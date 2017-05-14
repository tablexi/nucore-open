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
        return unless occupancy.present?

        find_or_create_order
        complete_order

        order
      end

      private

      def find_or_create_order
        if occupancy.order_detail_id?
          @order_detail = occupancy.order_detail
          @order = order_detail.order
        else
          create_order
        end
      end

      def complete_order
        order_detail.complete! if occupancy.order_completable?
      end

      def create_order
        ActiveRecord::Base.transaction do
          create_order_and_detail
          # TODO: This avoids an exception but results in un-purchased order on
          # problem occupancy, which may not appear in the problem-order scope
          if occupancy.account_id?
            order.validate_order!
            order.purchase!
          end
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
