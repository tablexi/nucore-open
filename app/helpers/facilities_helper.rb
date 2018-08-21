# frozen_string_literal: true

module FacilitiesHelper

  def daily_view_link
    if SettingsHelper.feature_on? :daily_view
      link_to t("facilities.show.daily_view"), facility_public_timeline_path(current_facility)
    end
  end

  def product_list_title(products, extra)
    title = products.first.class.model_name.human.pluralize
    title += " (#{extra})" if extra
    title.html_safe
  end

end
