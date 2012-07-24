module FacilitiesHelper
  def facility_default_admin_path(facility)
  	if facility.instruments.active.any?
  	  timeline_facility_reservations_path(facility)
  	else
  	  facility_orders_path(facility)
  	end
  end
end