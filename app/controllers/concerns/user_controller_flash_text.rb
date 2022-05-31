# frozen_string_literal: true

module UserControllerFlashText

  extend ActiveSupport::Concern

  # Builds the text for the creation success flash notice
  def creation_success_flash_text(user, facility)
    user_type = user.email_user? ? "external" : "internal"

    html(
      "create.success.#{user_type}",
      user_info: "#{user.full_name} (#{user.email})",
      user_link: facility_user_path(facility, user),
      price_group: price_group_name(user_type),
      app_name: t("app_name"),
      support_contact: support_contact
    )
  end

  def price_group_name(user_type)
    if user_type == "internal"
      Settings.price_group.name.base
    else
      Settings.price_group.name.external
    end
  end

  def support_contact
    if Settings.support_email.blank?
      ""
    else
      email = Settings.support_email
      " at [#{email}](mailto:#{email})"
    end
  end

end
