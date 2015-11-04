class NavTab::LinkCollection
  include Rails.application.routes.url_helpers
  include TranslationHelper

  attr_reader :ability, :facility

  def initialize(facility, ability)
    @facility = facility
    @ability = ability
  end

  def admin
    [
      home,
      admin_orders,
      admin_reservations,
      admin_billing,
      admin_products,
      admin_users,
      admin_reports,
      admin_facility,
    ].compact
  end

  def customer
    [home, orders, reservations, accounts].compact
  end

  private

  def accounts
    NavTab::Link.new(tab: :accounts, text: t_my(Account), url: accounts_path)
  end

  def admin_billing
    ability.can?(:manage_billing, facility) &&
      NavTab::Link.new(tab: :admin_billing, url: billing_tab_landing_path)
  end

  def admin_orders
    ability.can?(:administer, Order) &&
      NavTab::Link.new(tab: :admin_orders, url: facility_orders_path(facility))
  end

  def admin_products
    ability.can?(:administer, Product) &&
      NavTab::Link.new(tab: :admin_products, url: facility_products_path(facility))
  end

  def admin_reports
    ability.can?(:manage, ReportsController) &&
      NavTab::Link.new(
        tab: :admin_reports,
        subnav: [general_reports, instrument_utilization_reports],
      )
  end

  def admin_reservations
    ability.can?(:administer, Reservation) &&
      NavTab::Link.new(
        tab: :admin_reservations,
        url: timeline_facility_reservations_path(facility),
      )
  end

  def admin_users
    ability.can?(:administer, User) &&
      NavTab::Link.new(tab: :admin_users, url: facility_users_path(facility))
  end

  def admin_facility
    ability.can?(:edit, facility) &&
      NavTab::Link.new(tab: :admin_facility, url: manage_facility_path(facility))
  end

  def billing_tab_landing_path
    if SettingsHelper.has_review_period?
      facility_notifications_path(facility)
    else
      facility_transactions_path(facility)
    end
  end

  def general_reports
    NavTab::Link.new(
      text: I18n.t("pages.general_reports"),
      url: product_facility_general_reports_path(facility),
    )
  end

  def home
    NavTab::Link.new(tab: :home, url: root_path)
  end

  def instrument_utilization_reports
    NavTab::Link.new(
      text: I18n.t("pages.instrument_utilization_reports"),
      url: instrument_facility_instrument_reports_path(facility),
    )
  end

  def orders
    NavTab::Link.new(tab: :orders, text: t_my(Order), url: orders_path)
  end

  def reservations
    NavTab::Link.new(
      tab: :reservations,
      text: t_my(Reservation),
      url: reservations_path,
    )
  end
end
