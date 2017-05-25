module SecureRooms

  class SecureRoomOccupanciesController < ApplicationController

    layout "plain"

    def index
      @secure_room = SecureRoom.find_by(dashboard_token: params[:secure_room_id])
    end

  end

end
