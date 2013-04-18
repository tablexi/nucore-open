class OrderSearcher
  def initialize(user)
    @user = user
  end

  def search(query)
    return [] if query.nil?
    if query.include? '-'
      relation = search_full(query)
    else
      relation = OrderDetail.where("order_details.id = :id OR order_details.order_id = :id", :id => query)
    end
    relation.joins(:order).ordered
  end

  def search_full(query)
    order_id, order_detail_id = query.split('-')
    OrderDetail.where(:id => order_detail_id, :order_id => order_id)
  end
end