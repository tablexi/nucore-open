class NavTab::GlobalLinkCollection
  include Rails.application.routes.url_helpers

  def initialize(acting_as: false, user: nil)
    @acting_as = acting_as
    @user = user
  end

  def links
    [
      admin_cross_facility_users,
      global_settings,
      admin_cross_facility_billing,
    ].select(&:present?)
  end

  private

  def admin_cross_facility_billing
    if user_is?(:billing_administrator?)
      global_tab(tab: :admin_billing, url: facility_transactions_path("all"))
    end
  end

  def admin_cross_facility_users
    if user_is?(:account_manager?)
      global_tab(tab: :admin_users, url: facility_users_path("all"))
    end
  end

  def global_settings
    if user_is?(:administrator?)
      global_tab(tab: :global_settings, url: affiliates_path)
    end
  end

  def user_is?(role)
    !@acting_as && @user.try(role)
  end

  private

  def global_tab(args)
    NavTab::Link.new(args.merge(cross_facility: true))
  end
end
