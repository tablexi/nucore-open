module FacilitiesHelper
  def facility_default_admin_path(facility)
    if facility.instruments.active.any?
      timeline_facility_reservations_path(facility)
    else
      facility_orders_path(facility)
    end
  end

  def daily_view_link
    if SettingsHelper.feature_on? :daily_view
      link_to t('facilities.show.daily_view'), facility_public_timeline_path(current_facility)
    else
      nil
    end
  end

  def product_list_title(products, extra)
    title = products.first.class.model_name.human.pluralize
    title += " (#{extra})" if extra
    title.html_safe
  end
end
