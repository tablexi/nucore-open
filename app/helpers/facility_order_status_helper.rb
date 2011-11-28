module FacilityOrderStatusHelper
  def new_or_in_process_orders
    # will never include instrument order details
    facility_ods = current_facility.order_details.non_reservations
    
    case sort_column
      when 'order_number'
        facility_ods.find(:all,
                          :joins => 'INNER JOIN orders ON orders.id = order_details.order_id',
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "CONCAT(CONCAT(order_details.order_id, '-'), order_details.id) #{sort_direction}")
      when 'date'
        facility_ods.find(:all,
                          :joins => 'INNER JOIN orders ON orders.id = order_details.order_id',
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "orders.ordered_at #{sort_direction}")
      when 'product'
        facility_ods.find(:all,
                          :joins => 'INNER JOIN orders ON orders.id = order_details.order_id',
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "products.name #{sort_direction}, order_details.state, orders.ordered_at")
      when 'assigned_to'
        facility_ods.find(:all,
                          :joins => ['INNER JOIN order_statuses ON order_details.order_status_id = order_statuses.id ',
                                     'INNER JOIN orders ON orders.id = order_details.order_id ',
                                     "LEFT JOIN #{User.table_name} ON order_details.assigned_user_id = #{User.table_name}.id "],
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "#{User.table_name}.last_name #{sort_direction}, #{User.table_name}.first_name #{sort_direction}, order_statuses.name, orders.ordered_at")
      when 'status'
        facility_ods.find(:all,
                          :joins => ['INNER JOIN orders ON orders.id = order_details.order_id ',
                                     'INNER JOIN order_statuses ON order_details.order_status_id = order_statuses.id '],
                          :conditions => ['(order_details.state = ? OR order_details.state = ?) AND orders.state = ?', 'new', 'inprocess', 'purchased'],
                          :order => "order_statuses.name #{sort_direction}, orders.ordered_at")
      else
        facility_ods.new_or_inprocess
    end
  end
  
  def problem_orders
    current_facility.order_details.
      non_reservations.
      reject{|od| !od.problem_order?}
  end
  
  def disputed_orders
    current_facility.order_details.
      non_reservations.
      in_dispute
  end
  def sort_column
    params[:sort] || 'order_number'
  end
  
  def sort_direction
    (params[:dir] || '') == 'desc' ? 'desc' : 'asc'
  end
end