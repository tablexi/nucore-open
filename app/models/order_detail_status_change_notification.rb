class OrderDetailStatusChangeNotification < ActiveRecord::Observer
  observe :order_detail
  
  def after_save(order_detail)
  	return unless order_detail.order_status_id_changed?
    old_status = order_detail.order_status_id_was ? OrderStatus.find(order_detail.order_status_id_was) : nil
    new_status = order_detail.order_status
    hooks_to_run = self.class.status_change_hooks[new_status.downcase_name.to_sym]
    hooks_to_run.each { |hook| hook.on_status_change(order_detail, old_status, new_status) } if hooks_to_run
  end

  private

  def self.status_change_hooks
    hash = Settings.try(:order_details).try(:status_change_hooks).try(:to_hash) || {}
    new_hash = {}
    hash.each do |status,classes_listing|
      hooks = []
      Array.wrap(classes_listing).each do |class_definition|
        hooks << StatusChangeListener.build(class_definition)
      end
      new_hash[status] = hooks
    end
    new_hash
  end
end

class StatusChangeListener
  attr_reader :settings
  def self.build(input)
    if input.respond_to? :to_hash
      hash = input.to_hash
      hash.delete(:class).constantize.new(hash)
    else
      input.constantize.new({})
    end
  end
  def initialize(settings={})
    @settings = settings
  end
  def on_status_change(order_detail, old_status, new_status)
    # do nothing
  end
end