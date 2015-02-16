namespace :order_details  do
  desc "mark order_details with past reservations as complete"
  task :expire_reservations => :environment do
    complete    = OrderStatus.find_by_name!('Complete')
    order_details = OrderDetail.purchased_active_reservations.where("reservations.reserve_end_at < ?", Time.zone.now - 12.hours).
                               readonly(false).all
    order_details.each do |od|
      od.transaction do
        begin
          od.change_status!(complete)
          od.fulfilled_at = od.reservation.reserve_end_at
          next unless od.price_policy
          costs = od.price_policy.calculate_cost_and_subsidy(od.reservation)
          next if costs.blank?
          od.actual_cost    = costs[:cost]
          od.actual_subsidy = costs[:subsidy]
          od.save!
        rescue Exception => e
          STDERR.puts "Error on Order # #{od} - #{e}\n#{e.backtrace.join("\n")}"
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  desc "automatically switch off auto_logout instrument"
  task :auto_logout => :environment do
    AutoLogout.new.perform
  end

  desc "task to remove merge orders that have been abandoned. See Task #48377"
  task :remove_merge_orders => :environment do
    stale_merge_orders=Order.where("merge_with_order_id IS NOT NULL AND created_at <= ?", Time.zone.now - 4.weeks).all
    stale_merge_orders.each{|order| order.destroy }
  end

  desc "Retouch all complete order details and recalculate pricing"
  task :recalculate_prices, [:facility_slug] => :environment do |t, args|
    Facility.find_by_url_name('path').order_details.where(:state => 'complete').each do |od|
      old_cost = od.actual_cost
      old_subsidy = od.actual_subsidy
      old_total = od.actual_total
      old_price_group = od.price_policy.try(:price_group)
      od.assign_price_policy(od.fulfilled_at)
      puts "#{od}|#{od.order_status}|#{od.account}|#{od.user}|#{od.product}|#{od.fulfilled_at}|#{old_price_group}|#{old_cost}|#{old_subsidy}|#{old_total}|#{od.price_policy.try(:price_group)}|#{od.actual_cost}|#{od.actual_subsidy}|#{od.actual_total}|#{od.actual_total == old_total}"
    end

  end

  desc "Uncancels a list of order details. The file should contain just the OD ID, one per line"
  task :uncancel, [:filename] => :environment do |t, args|
    uncanceler = OrderUncanceler.new
    File.open(args[:filename]).each_line do |line|
      order_detail = OrderDetail.find_by_id(line.chomp)
      if order_detail
        uncanceler.uncancel_to_complete(order_detail)
      else
        puts "Could not find order detail #{line}"
      end
    end
  end
end
