# frozen_string_literal: true

class ProductPresenter < SimpleDelegator

  def with_archived_tag
    is_archived? ? I18n.t("products.archived", product: name) : name
  end

end
