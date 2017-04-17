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
          existing_occupancy.update!(exit_event: event)
        elsif new_occupant? && entering?
          new_occupancy.update!(entry_event: event)
        else
          # TODO: Add error cases
          raise NotImplementedError
        end

        existing_occupancy || new_occupancy
      end

      def existing_occupancy
        # TODO: clean up scope (find_or_create?)
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
