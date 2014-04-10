class OrderSearcher
  def initialize(user)
    @user = user
  end

  def search(query)
    relation = nil

    if query =~ /\d+-\d+/
      relation = search_full(query)
    elsif query =~ /[A-Z]+-\d+/
      relation = search_external query
    elsif query =~ /\d+/
      relation = OrderDetail.where("order_details.id = :id OR order_details.order_id = :id", :id => query)
    end

    return [] unless relation
    restrict_to_user(relation.joins(:order).ordered)
  end

  def search_full(query)
    order_id, order_detail_id = query.split('-')
    OrderDetail.where(:id => order_detail_id, :order_id => order_id)
  end

  def search_external(query)
    OrderDetail.joins(:external_service_receiver).where('external_service_receivers.external_id = ?', query)
  end

  def restrict_to_user(order_details)
    order_details.select do |od|
      ability = Ability.new(@user, od, nil)
      ability.can? :show, od
    end
  end
end
