module NavTab

  extend ActiveSupport::Concern

  included do
    class_attribute :customer_actions
    class_attribute :admin_actions

    helper_method(:admin_cross_facility_billing_tab_link)
    helper_method(:customer_tab?)
    helper_method(:admin_tab?)
    helper_method(:global_settings_link)
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

  def admin_cross_facility_billing_tab_link
    @admin_cross_facility_billing_tab_link ||=
      Link.new(cross_facility: true, tab: :admin_billing)
  end

  # Returns true if the current action is an admin tab action
  def admin_tab?
    ((self.class.admin_actions || []) & [action_name.to_sym, :all]).any?
  end

  def navigation_links
    case
    when customer_tab? && acting_user.present?
      link_collection.customer
    when admin_tab? && current_facility.present?
      link_collection.admin
    else
      link_collection.default
    end
  end

  protected

  # Returns true if the current action is a customer tab action
  def customer_tab?
    ((self.class.customer_actions || []) & [action_name.to_sym, :all]).any?
  end

  private

  def global_settings_link
    @global_settings_link ||=
      NavTab::Link.new(tab: :global_settings, url: affiliates_path)
  end

  def link_collection
    @link_collection ||= LinkCollection.new(current_facility, current_ability)
  end

end
