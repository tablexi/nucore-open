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
          associate_exit_to(existing_occupancy)
        elsif new_occupant? && entering?
          associate_entry_to(new_occupancy)
        elsif new_occupant? && exiting?
          new_occupancy.mark_orphaned!
          associate_exit_to(new_occupancy)
        elsif current_occupant? && entering?
          existing_occupancy.mark_orphaned!
          associate_entry_to(new_occupancy)
        end
      end

      private

      def associate_entry_to(occupancy)
        occupancy.update!(
          entry_event: event,
          entry_at: Time.current,
        )
        occupancy
      end

      def associate_exit_to(occupancy)
        occupancy.update!(
          exit_event: event,
          exit_at: Time.current,
        )
        occupancy
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
