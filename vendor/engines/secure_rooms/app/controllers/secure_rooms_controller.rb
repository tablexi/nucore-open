# frozen_string_literal: true

class SecureRoomsController < ProductsCommonController

    def edit_ethernet_ports
    end

    def update_ethernet_ports
      respond_to do |format|
        if @product.update(ethernet_resource_params)
          flash[:notice] = "Secure room ethernet ports were successfully updated."
          format.html { redirect_to(facility_secure_room_card_readers_path(@current_facility, @product)) }
        else
          format.html { render action: "edit_ethernet_ports" }
        end
      end
    end

    private

    def ethernet_resource_params
      params.require("secure_room").permit(:card_reader_room_number, :card_reader_circuit_number, :card_reader_port_number,
                                            :card_reader_location_description, :tablet_room_number, :tablet_circuit_number,\
                                            :tablet_port_number, :tablet_location_description)
    end
end
