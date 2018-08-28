# frozen_string_literal: true

class OrderDetailObserver < ActiveRecord::Observer

  def after_destroy(order_detail)
    # merge orders should be cleaned up if they are without order details
    order = order_detail.order.reload
    order.destroy if order.to_be_merged? && order.order_details.empty?
  end

  def before_save(order_detail)
    order = order_detail.order
    product = order_detail.product

    if order.to_be_merged? && (product.is_a?(Item) ||
                              (product.is_a?(Service) && order_detail.valid_service_meta?) ||
                              (product.is_a?(Instrument) && order_detail.valid_reservation?))

      # move this detail to the original order if it is 100% valid
      order_detail.order_id = order.merge_order.id
    end
  end

  def after_save(order_detail)
    if order_detail.order_status_id_changed?
      old_status = order_detail.order_status_id_was ? OrderStatus.find(order_detail.order_status_id_was) : nil
      new_status = order_detail.order_status
      hooks_to_run = self.class.status_change_hooks[new_status.downcase_name.to_sym]
      hooks_to_run.each { |hook| hook.on_status_change(order_detail, old_status, new_status) } if hooks_to_run
    end

    changes = order_detail.changes
    # check to see if #before_save switch order ids on us
    if changes.key?("order_id") && changes["order_id"][0].present?
      merge_order = Order.find changes["order_id"][0].to_i

      # clean up merge notifications
      MergeNotification.about(order_detail).first.try(:destroy)

      # clean up detail-less merge orders
      merge_order.destroy if merge_order.to_be_merged? && merge_order.order_details.blank?
    end
  end

  def self.status_change_hooks
    hash = Settings.try(:order_details).try(:status_change_hooks).try(:to_hash) || {}
    new_hash = {}
    hash.each do |status, classes_listing|
      hooks = []
      Array.wrap(classes_listing).each do |class_definition|
        hooks << build_hook(class_definition)
      end
      new_hash[status] = hooks
    end
    new_hash
  end

  private

  def self.build_hook(class_definition)
    if class_definition.respond_to? :to_hash
      hash = class_definition.to_hash
      clazz = hash.delete(:class).constantize
    else
      hash = {}
      clazz = class_definition.constantize
    end
    # Create a new istance and set settings if the class has that setter
    inst = clazz.new
    inst.settings = hash if inst.respond_to?(:settings=)
    inst
  end

end
