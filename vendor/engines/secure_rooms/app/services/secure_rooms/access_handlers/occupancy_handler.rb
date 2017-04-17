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
        event_attribute =
          if entering?
            { entry_event: event }
          else
            { exit_event: event }
          end

        if current_occupant? && exiting?
          existing_occupancy.update!(event_attribute)
        elsif new_occupant? && entering?
          new_occupancy.update!(event_attribute)
        end

        existing_occupancy || new_occupancy
      end

      def existing_occupancy
        # TODO: clean up scope
        @existing_occupancy ||= event.secure_room.occupancies.current.where(user: event.user).first
      end

      def new_occupancy
        @new_occupancy ||= Occupancy.new(
          secure_room: event.secure_room,
          user: event.user,
          account: event.account,
        )
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
