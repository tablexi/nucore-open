# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  include DateHelper
  include TranslationHelper

  def app_name
    t :app_name
    # NUCore.app_name
  end

  def can_create_users?
    SettingsHelper.feature_on?(:create_users) && current_ability.can?(:create, User)
  end

  def html_title(title = nil)
    full_title = title.blank? ? "" : "#{title} - "
    (full_title + app_name).html_safe
  end

  def order_detail_description(order_detail) # TODO: deprecate in favor of OrderDetailPresenter#description_as_html
    OrderDetailPresenter.new(order_detail).description_as_html
  end

  def order_detail_description_as_html(order_detail) # TODO: deprecate in favor of OrderDetailPresenter#description_as_html
    OrderDetailPresenter.new(order_detail).description_as_html
  end

  def order_detail_description_as_text(order_detail) # TODO: move this into OrderDetailPresenter
    name = order_detail.product.to_s
    if order_detail.bundle
      name.prepend("#{order_detail.bundle} -- ")
    else
      name
    end.html_safe
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, { sort: column, dir: direction }, class: (column == sort_column ? sort_direction : "sortable")
  end

  #
  # currency display helpers
  [:total, :cost, :subsidy].each do |type|
    define_method("show_actual_#{type}") { |order_detail| show_currency(order_detail, "actual_#{type}") }
    define_method("show_estimated_#{type}") { |order_detail| show_currency(order_detail, "estimated_#{type}") }
  end

  def facility_product_path(facility, product)
    method = "facility_#{product.class.model_name.to_s.underscore}_path"
    send(method, facility, product)
  end

  private

  def show_currency(order_detail, method)
    val = order_detail.method(method).call
    val ? h(number_to_currency(val)) : ""
  end

  def menu_facilities
    return [] unless session_user
    session_user.facilities
  end

  def render_if_exists(partial, options = {})
    # The third argument `true` checks for partials (prefixed with _)
    if lookup_context.template_exists?(partial, lookup_context.prefixes, true)
      render partial, options
    end
  end

end
