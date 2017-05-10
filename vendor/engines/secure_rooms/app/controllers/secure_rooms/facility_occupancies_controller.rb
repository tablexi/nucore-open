module SecureRooms

  class FacilityOccupanciesController < ApplicationController

    include TabCountHelper

    admin_tab     :all
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility

    def initialize
      super
      @active_tab = "admin_occupancies"
    end

    def index
    end

  end

end
