module FacilitiesHelper
  def facility_default_admin_path(facility)
  	if facility.instruments.active.any?
  	  timeline_facility_reservations_path(facility)
  	else
  	  facility_orders_path(facility)
  	end
  end

  def product_list_title(products, extra)
    title = products.first.class.model_name.human.pluralize
    title += " (#{extra})" if extra
    title.html_safe
  end
end
