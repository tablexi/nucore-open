# frozen_string_literal: true

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
        return if user_exempt_from_purchase?

        find_or_create_order
        complete_order if occupancy.order_completable?

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
        if occupancy.orphaned_at?
          MoveToProblemQueue.move!(order_detail)
        else
          order_detail.complete!
        end
      end

      def create_order
        ActiveRecord::Base.transaction do
          assign_account unless occupancy.account_id?

          create_order_and_detail
          order.validate_order!
          order.purchase!
        end
      end

      def assign_account
        accounts = occupancy.user.accounts_for_product(occupancy.secure_room)
        occupancy.update(account: accounts.first)
      end

      # Whether or not an occupant must pay for their time is determined by
      # CheckAccess at scan-in time. In the event we don't have access to
      # scan-in information, we check the user's access with a room's in-reader
      # to find what the verdict would have been. A verdict returning accounts
      # signifies the user would have needed to select one to enter.
      def user_exempt_from_purchase?
        in_reader = occupancy.secure_room.card_readers.ingress.first
        SecureRooms::CheckAccess.new.authorize(occupancy.user, in_reader).accounts.blank?
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
