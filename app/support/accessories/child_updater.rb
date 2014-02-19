class Accessories::ChildUpdater
  def initialize(order_detail)
    @order_detail = order_detail
  end

  # Used in OrderDetail after_save hook
  def update_children
    @order_detail.child_order_details.each_with_object([]) do |od, changed|
      update_child_detail(od)
      changed << od if od.changed?
      if @order_detail.complete? && od.fulfilled_at.nil?
        od.backdate_to_complete! @order_detail.fulfilled_at
      else
        od.save
      end
    end
  end

  private

  def update_child_detail(od)
    decorated_od = Accessories::Scaling.decorate(od)
    od.account = @order_detail.account
    decorated_od.update_quantity
    od.assign_actual_price
  end
end
