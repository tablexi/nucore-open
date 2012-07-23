class OrderDetailStatusChangeNotification < ActiveRecord::Observer
  observe :order_detail
  
  def after_save(order_detail)
  	return unless order_detail.order_status_id_changed?
    old_status = order_detail.order_status_id_was ? OrderStatus.find(order_detail.order_status_id_was) : nil
    new_status = order_detail.order_status
    SettingsHelper::status_change_hooks.each do |status, hooks|
      [*hooks].each { |hook| hook.constantize.new.on_status_change(order_detail, old_status, new_status) } if new_status.name.downcase.gsub(' ', '_') == status.to_s.downcase
    end
  end
end