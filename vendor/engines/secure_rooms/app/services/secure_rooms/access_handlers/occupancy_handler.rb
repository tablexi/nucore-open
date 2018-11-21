# frozen_string_literal: true

module SecureRooms

  module AccessHandlers

    class OccupancyHandler

      attr_reader :event

      def self.process(event)
        new(event).process
      end

      def initialize(event)
        @event = event
      end

      def process
        Rails.logger.info("[SecureRooms] Entered SecureRooms::AccessHandlers::EventHandler#process")

        return unless event.success?

        result = if current_occupant? && exiting?
          Rails.logger.info("[SecureRooms] Processing branch current_occupant? && exiting? (existing occupancy id: #{existing_occupancy.id})")
          existing_occupancy.associate_exit!(event)
        elsif new_occupant? && entering?
          Rails.logger.info("[SecureRooms] Processing branch new_occupant? && entering? (new occupancy id: #{new_occupancy.id})")
          new_occupancy.associate_exit!(event) if entry_only?
          new_occupancy.associate_entry!(event)
        elsif new_occupant? && exiting?
          Rails.logger.info("[SecureRooms] Processing branch new_occupant? && exiting? (new occupancy id: #{new_occupancy.id})")
          new_occupancy.mark_orphaned!
          new_occupancy.associate_exit!(event)
        elsif current_occupant? && entering?
          Rails.logger.info("[SecureRooms] Processing branch current_occupant? && entering? (existing occupancy id: #{existing_occupancy.id})")
          complete_existing_occupancy!
          new_occupancy.associate_entry!(event)
        else
          raise NotImplementedError, "Encountered unexpected scan context"
        end

        Rails.logger.info("[SecureRooms] Exiting SecureRooms::AccessHandlers::EventHandler#process")
        result
      end

      private

      def entry_only?
        event.secure_room.entry_only?
      end

      def existing_occupancy
        @existing_occupancy ||= Occupancy.current.find_by(
          user: event.user,
          secure_room: event.secure_room,
        )
      end

      def new_occupancy
        @new_occupancy ||= Occupancy.new(
          secure_room: event.secure_room,
          user: event.user,
          account: event.account,
        )
      end

      def complete_existing_occupancy!
        existing_occupancy.mark_orphaned!
        OrderHandler.process(existing_occupancy)
      end

      def current_occupant?
        existing_occupancy.present?
      end

      def new_occupant?
        existing_occupancy.blank?
      end

      def entering?
        event.ingress?
      end

      def exiting?
        event.egress?
      end

    end

  end

end
