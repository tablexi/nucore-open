class OrderUncanceler
  def initialize
    @complete_status = OrderStatus.complete.first
    @canceled_status = OrderStatus.cancelled.first
  end

  def uncancel_to_complete(order_detail)
    unless order_detail.cancelled?
      puts "#{order_detail} was not in cancelled state"
      return
    end

    order_detail.transaction do
      begin
        order_detail.reservation.update_attributes!(
          :canceled_by => nil,
          :canceled_at => nil,
          :canceled_reason => nil,
          :actual_start_at => order_detail.reservation.reserve_start_at,
          :actual_end_at => order_detail.reservation.reserve_end_at)

        order_detail.update_attributes!(
          :order_status => @complete_status,
          :state => 'complete',
          :fulfilled_at => order_detail.reservation.reserve_end_at)

        order_detail.assign_price_policy(order_detail.reservation.reserve_end_at)
        order_detail.save!
        puts "#{order_detail} was uncancelled"
        true
      rescue => e
        puts "Could not save #{order_detail} because #{e.message}"
        raise ActiveRecord::Rollback
      end
    end
  end
end
