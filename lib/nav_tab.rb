module NavTab
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.helper_method(:customer_tab?)
    controller.helper_method(:admin_tab?)
  end

  module ClassMethods
    # Specifies that the named actions should show the customer tabs (which is enforced by set_tab).
    def customer_tab(*actions)
      write_inheritable_array(:customer_actions, actions)
    end

    # Specifies that the named actions should show the admin tabs (which is enforced by set_tab).
    def admin_tab(*actions)
      write_inheritable_array(:admin_actions, actions)
    end
  end

  protected

  # Returns true if the current action is a customer tab action
  def customer_tab?
    (self.class.read_inheritable_attribute(:customer_actions) || []).include?(action_name.to_sym) ||
    (self.class.read_inheritable_attribute(:customer_actions) || []).include?(:all)
  end
  
  # Returns true if the current action is an admin tab action
  def admin_tab?
    (self.class.read_inheritable_attribute(:admin_actions) || []).include?(action_name.to_sym) ||
    (self.class.read_inheritable_attribute(:admin_actions) || []).include?(:all)
  end

end