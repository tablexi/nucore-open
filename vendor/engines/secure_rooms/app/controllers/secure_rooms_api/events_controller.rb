module SecureRoomsApi

  class EventsController < SecureRoomsApi::ApiController

    def create
      Rails.logger.info "SecureRoomsApi Event: #{params}"
      render nothing: true
    end

  end

end
