module SecureRoomsApi

  class EventsController < SecureRoomsApi::ApiController

    before_action :parse_time

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

    # TODO: not certain this goes here but awaiting discussion
    def parse_time
      format_str = "%H:%M:%S %Z %m/%d/%Y"
      params[:message_time] = DateTime.strptime(params[:message_time], format_str)
    end

  end

end
