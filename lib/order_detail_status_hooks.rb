module OrderDetailStatusHooks
  extend ActiveSupport::Concern
  included do
    after_save :trigger_order_status_change_hooks, :if => :order_status_id_changed?
  end
  
  def trigger_order_status_change_hooks
    # don't trigger for new and validated, since they're only sitting in a cart
    return true unless order.state == 'purchased'
    old_status = order_status_id_was ? OrderStatus.find(order_status_id_was) : nil
    new_status = order_status
    SettingsHelper::status_change_hooks.each do |status, hooks|
      [*hooks].each { |hook| hook.constantize.new.on_status_change(self, old_status, new_status) } if new_status.name.downcase.gsub(' ', '_') == status.to_s.downcase
    end
  end


end