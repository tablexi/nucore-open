module NavTab

  extend ActiveSupport::Concern

  included do
    class_attribute :customer_actions
    class_attribute :admin_actions

    helper_method(:customer_tab?)
    helper_method(:admin_tab?)
    helper_method(:navigation_links)
  end

  module ClassMethods
    # Specifies that the named actions should show the customer tabs (which is enforced by set_tab).
    def customer_tab(*actions)
      self.customer_actions = actions
    end

    # Specifies that the named actions should show the admin tabs (which is enforced by set_tab).
    def admin_tab(*actions)
      self.admin_actions = actions
    end
  end

  # Returns true if the current action is an admin tab action
  def admin_tab?
    ((self.class.admin_actions || []) & [action_name.to_sym, :all]).any?
  end

  def navigation_links
    links = [ home_tab_link ]

    case
    when customer_tab? && acting_user.present?
      links.push(orders_tab_link, reservations_tab_link, accounts_tab_link)
    when admin_tab? && current_facility.present?
      links << admin_orders_tab_link if can?(:administer, Order)
      links << admin_reservations_tab_link if can?(:administer, Reservation)
      links << admin_billing_tab_link if can?(:manage_billing, current_facility)
      links << admin_products_tab_link if can?(:administer, Product)
      links << admin_users_tab_link if can?(:administer, User)
      links << admin_reports_tab_link if can?(:manage, ReportsController)
      links << admin_facility_tab_link if can?(:edit, current_facility)
    end

    links
  end

  protected

  # Returns true if the current action is a customer tab action
  def customer_tab?
    ((self.class.customer_actions || []) & [action_name.to_sym, :all]).any?
  end

  private

  def accounts_tab_link
    {
      tab_name: "accounts",
      text: I18n.t("pages.my_tab", model: Account.model_name.human.pluralize),
      url: accounts_path,
    }
  end

  def admin_billing_tab_link
    {
      tab_name: "admin_billing",
      text: "Billing",
      url: billing_tab_landing_path,
    }
  end

  def billing_tab_landing_path
    if SettingsHelper::has_review_period?
      facility_notifications_path(current_facility)
    else
      facility_transactions_path(current_facility)
    end
  end

  def admin_facility_tab_link
    {
      tab_name: "admin_facility",
      text: "Admin",
      url: manage_facility_path(current_facility),
    }
  end

  def admin_orders_tab_link
    {
      tab_name: "admin_orders",
      text: "Orders",
      url: facility_orders_path(current_facility),
    }
  end

  def admin_products_tab_link
    {
      tab_name: "admin_products",
      text: "Products",
      url: facility_products_path(current_facility),
    }
  end

  def admin_reports_tab_link
    reports_sub = [{ url: product_facility_general_reports_path(current_facility), text: "General"},
                   { url: instrument_facility_instrument_reports_path(current_facility), text: "Instrument Utilization"}]
    { text: "Reports", tab_name: "admin_reports", subnav: reports_sub }
  end

  def admin_users_tab_link
    {
      tab_name: "admin_users",
      text: "Users",
      url: facility_users_path(current_facility),
    }
  end

  def admin_reservations_tab_link
    {
      tab_name: "admin_reservations",
      text: "Reservations",
      url: timeline_facility_reservations_path(current_facility),
    }
  end

  def home_tab_link
    { url: root_path, text: "Home", tab_name: "home" }
  end

  def orders_tab_link
    {
      tab_name: "orders",
      text: I18n.t("pages.my_tab", model: Order.model_name.human.pluralize),
      url: orders_url,
    }
  end

  def reservations_tab_link
    {
      tab_name: "reservations",
      text: I18n.t("pages.my_tab", model: Reservation.model_name.human.pluralize),
      url: reservations_url,
    }
  end
end
