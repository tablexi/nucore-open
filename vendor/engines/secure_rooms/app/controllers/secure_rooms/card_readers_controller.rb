module SecureRooms

  class CardReadersController < ApplicationController

    admin_tab :all
    customer_tab :password

    layout "two_column"

    before_action :init_current_facility
    before_action :init_product
    before_action :load_card_reader, except: [:index]
    before_action :authenticate_user!
    before_action :check_acting_as

    def initialize
      @active_tab = "secure_rooms"
      super
    end

    def index
      @card_readers = @product.card_readers
    end

    def new; end

    def edit; end

    def create
      @card_reader.assign_attributes(card_reader_params)
      return render :new unless @card_reader.save
      redirect_to facility_secure_room_card_readers_path(current_facility, @product)
    end

    def update
      @card_reader.assign_attributes(card_reader_params)
      return render :edit unless @card_reader.save
      redirect_to facility_secure_room_card_readers_path(current_facility, @product)
    end

    def destroy
      @card_reader.destroy!
      redirect_to facility_secure_room_card_readers_path(current_facility, @product)
    end

    private

    def init_product
      @product = current_facility.products(SecureRoom).find_by!(url_name: params[:secure_room_id])
    end

    def load_card_reader
      scope = @product.card_readers
      @card_reader = params[:id] ? scope.find(params[:id]) : scope.build
    end

    def card_reader_params
      params.require(:card_reader).permit(:description, :card_reader_number, :control_device_number)
    end

  end

end
