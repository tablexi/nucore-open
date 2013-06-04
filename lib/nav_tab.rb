module NavTab

  extend ActiveSupport::Concern

  included do
    class_attribute :customer_actions
    class_attribute :admin_actions

    helper_method(:customer_tab?)
    helper_method(:admin_tab?)
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

  protected

  # Returns true if the current action is a customer tab action
  def customer_tab?
    ((self.class.customer_actions || []) & [action_name.to_sym, :all]).any?
  end

  # Returns true if the current action is an admin tab action
  def admin_tab?
    ((self.class.admin_actions || []) & [action_name.to_sym, :all]).any?
  end

end