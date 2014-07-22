class OrderSearcher
  include NUCore::Database::CaseSensitivityHelper

  def initialize(user)
    @user = user
  end

  def search(query)
    return [] unless query
    query.gsub!(/\s/,"")

    relation = nil
    if query =~ /\A\d+-\d+\z/
      relation = search_full(query)
    elsif query =~ /\A[A-Za-z]+-\d+\z/
      relation = search_external query
    elsif query =~ /\A\d+\z/
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
    insensitive_where OrderDetail.joins(:external_service_receiver), 'external_service_receivers.external_id', query
  end

  def restrict_to_user(order_details)
    order_details.select do |od|
      ability = Ability.new(@user, od, nil)
      ability.can? :show, od
    end
  end
end
