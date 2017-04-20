module SecureRooms

  class OccupanciesController < ApplicationController

    admin_tab :all

    layout "two_column"

    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility
    before_action :init_product
    load_and_authorize_resource through: :product

    def initialize
      @active_tab = "secure_rooms"
      super
    end

    def index
      @occupancies = @product.occupancies.current
      @problem_occupancies = @product.occupancies.orphaned
    end

    private

    def init_product
      @product = current_facility.products(SecureRoom).find_by!(url_name: params[:secure_room_id])
    end

  end

end
