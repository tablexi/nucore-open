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
        if current_occupant? && exiting?
          existing_occupancy.associate_exit!(event)
        elsif new_occupant? && entering?
          new_occupancy.associate_entry!(event)
        elsif new_occupant? && exiting?
          new_occupancy.mark_orphaned!
          new_occupancy.associate_exit!(event)
        elsif current_occupant? && entering?
          complete_existing_occupancy!
          new_occupancy.associate_entry!(event)
        else
          raise NotImplementedError, "Encountered unexpected scan context"
        end
      end

      private

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
        if existing_occupancy.order_completable?
          existing_occupancy.order_detail.complete!
        end
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
