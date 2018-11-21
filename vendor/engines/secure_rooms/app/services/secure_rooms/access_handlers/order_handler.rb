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
        Rails.logger.info("[SecureRooms] Entered SecureRooms::AccessHandlers::OrderHandler#process (occupancy id #{occupancy.id})")
        return if user_exempt_from_purchase?

        find_or_create_order
        Rails.logger.info("[SecureRooms] order id #{order.id}; order detail id #{@order_detail.id}")
        Rails.logger.info("[SecureRooms] occupancy.order_completable? = #{occupancy.order_completable?}")
        complete_order if occupancy.order_completable?

        Rails.logger.info("[SecureRooms] Exiting SecureRooms::AccessHandlers::OrderHandler#process")
        order
      end

      private

      def find_or_create_order
        Rails.logger.info("[SecureRooms] Entered SecureRooms::AccessHandlers::OrderHandler#find_or_create_order")
        if occupancy.order_detail_id?
          Rails.logger.info("[SecureRooms] Processing branch occupancy.order_detail_id?")
          @order_detail = occupancy.order_detail
          @order = order_detail.order
        else
          Rails.logger.info("[SecureRooms] Processing branch else")
          create_order
        end
        Rails.logger.info("[SecureRooms] Exiting SecureRooms::AccessHandlers::OrderHandler#find_or_create_order")
      end

      def complete_order
        Rails.logger.info("[SecureRooms] Entered SecureRooms::AccessHandlers::OrderHandler#complete_order")
        if occupancy.orphaned_at?
          Rails.logger.info("Processing branch occupancy.orphaned_at?")
          MoveToProblemQueue.move!(order_detail)
        else
          Rails.logger.info("[SecureRooms] Processing branch else")
          order_detail.complete!
        end
        Rails.logger.info("[SecureRooms] Exiting SecureRooms::AccessHandlers::OrderHandler#complete_order")
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
        Rails.logger.info("[SecureRooms] Entered SecureRooms::AccessHandlers::OrderHandler#user_exempt_from_purchase?")
        in_reader = occupancy.secure_room.card_readers.ingress.first
        result = SecureRooms::CheckAccess.new.authorize(occupancy.user, in_reader).accounts.blank?
        Rails.logger.info("[SecureRooms] Exiting SecureRooms::AccessHandlers::OrderHandler#user_exempt_from_purchase? and returning #{result}")
        result
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
