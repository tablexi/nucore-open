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
          existing_occupancy.update!(
            exit_event: event,
            exit_at: Time.current,
          )
        elsif new_occupant? && entering?
          new_occupancy.update!(
            entry_event: event,
            entry_at: Time.current,
          )
        else
          # TODO: Add error cases
          raise NotImplementedError
        end

        existing_occupancy || new_occupancy
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
