# frozen_string_literal: true

class Accessories::ChildUpdater

  def initialize(order_detail)
    @order_detail = order_detail
  end

  # Used in OrderDetail after_save hook
  def update_children
    @order_detail.child_order_details.each_with_object([]) do |od, changed|
      update_child_detail(od)
      changed << od if od.changed?
      save_order_detail(od)
    end
  end

  private

  def save_order_detail(od)
    if status_changed?(od)
      change_status! od
    else
      od.save
    end
  end

  def status_changed?(od)
    @order_detail.order_status_id_changed? && @order_detail.order_status_id_was == od.order_status_id
  end

  def change_status!(od)
    if @order_detail.complete? && od.fulfilled_at.nil?
      od.backdate_to_complete! @order_detail.fulfilled_at
    else
      od.update_order_status! @order_detail.order_status_updated_by, @order_detail.order_status
    end
  end

  def update_child_detail(od)
    decorated_od = Accessories::Scaling.decorate(od)
    od.account = @order_detail.account
    decorated_od.update_quantity
  end

end
