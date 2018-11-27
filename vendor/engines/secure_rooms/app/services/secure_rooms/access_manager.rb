# frozen_string_literal: true

module SecureRooms

  class AccessManager

    PROCESSING_CHAIN = [
      SecureRooms::AccessHandlers::EventHandler,
      SecureRooms::AccessHandlers::OccupancyHandler,
      SecureRooms::AccessHandlers::OrderHandler,
    ].freeze

    def self.process(verdict)
      Rails.logger.info("[SecureRooms] Entered SecureRooms::AccessManager.process")

      PROCESSING_CHAIN.inject(verdict) do |result, handler|
        result = handler.process(result)
        result || break
      end

      Rails.logger.info("[SecureRooms] Exiting SecureRooms::AccessManager.process")
    end

  end

end
