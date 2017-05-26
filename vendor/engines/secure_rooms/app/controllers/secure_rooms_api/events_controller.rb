module SecureRoomsApi

  class EventsController < SecureRoomsApi::ApiController

    def create
      SecureRooms::Alert.create(alert_params)
      render nothing: true
    end

    private

    def alert_params
      params.permit(
        :additional_data,
        :class_code,
        :event_code,
        :event_description,
        :mac_address,
        :message_id,
        :message_time,
        :message_type,
        :priority,
        :task_code,
        :task_description,
      )
    end

  end

end
