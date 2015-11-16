module AffiliatesHelper

  def delete_affiliate_link(affiliate)
    link_to(
      I18n.t("affiliates.remove.label"),
      affiliate_path(affiliate),
      confirm: I18n.t("affiliates.remove.confirm", name: affiliate.name),
      method: :delete,
    )
  end

  def edit_affiliate_link(affiliate)
    link_to I18n.t("affiliates.edit"), edit_affiliate_path(affiliate)
  end

end
