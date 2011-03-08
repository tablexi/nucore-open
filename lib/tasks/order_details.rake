namespace :order_details  do
  desc "mark order_details with past reservations as reviewable"  
  task :expire_reservations => :environment do
    reviewable    = OrderStatus.find_by_name!('Reviewable')
    order_details = OrderDetail.find(:all,
                                     :conditions => ["(state = 'new' OR state = 'inprocess') AND reservations.reserve_end_at < ? AND canceled_at IS NULL", Time.zone.now - 12.hours],
                                     :joins => 'INNER JOIN reservations ON reservations.order_detail_id = order_details.id',
                                     :readonly => false)
    order_details.each do |od|
      od.transaction do
        begin
          od.change_status!(reviewable)
          costs = od.price_policy.calculate_actual_instrument_costs(od.reservation)
          if costs
            od.actual_cost    = costs[:actual_cost]
            od.actual_subsidy = costs[:actual_subsidy]
            od.save!
          end
        rescue Exception => e
          STDERR.puts "Error on Order # #{od} - #{e}"
          raise ActiveRecord::Rollback
        end
      end
    end
  end
  
  desc "automatically switch off auto_logout instrument"
  task :auto_logout => :environment do
    reviewable    = OrderStatus.find_by_name!('Reviewable')
    order_details = OrderDetail.find(:all,
                                     :conditions => ["(state = 'new' OR state = 'inprocess') AND reservations.actual_end_at IS NULL AND canceled_at IS NULL AND products.auto_logout = 1 AND reserve_end_at < ?", Time.zone.now - 1.hour],
                                     :joins => ['INNER JOIN products ON order_details.product_id = products.id', 'INNER JOIN reservations ON reservations.order_detail_id = order_details.id'],
                                     :readonly => false)
    order_details.each do |od|
      od.transaction do
        begin
          od.reservation.actual_end_at = Time.zone.now
          od.change_status!(reviewable)
          costs = od.price_policy.calculate_actual_instrument_costs(od.reservation)
          if costs
            od.actual_cost    = costs[:actual_cost]
            od.actual_subsidy = costs[:actual_subsidy]
            od.save!
          end
        rescue Exception => e
          STDERR.puts "Error on Order # #{od} - #{e}"
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
