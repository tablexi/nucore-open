class Item < Product
  has_many :item_price_policies, :foreign_key => :product_id

  validates_presence_of :initial_order_status_id, :facility_account_id
  validates_numericality_of :account, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 99999

  def cheapest_price_policy (groups = [])
    return nil if groups.empty?

    min = nil
    cheapest_total = 0
    current_price_policies.each do |pp|
      if !pp.expired? && !pp.restrict_purchase? && groups.include?(pp.price_group)
        costs = pp.calculate_cost_and_subsidy
        total = costs[:cost] - costs[:subsidy]
        if min.nil? || total < cheapest_total
          cheapest_total = total
          min = pp
        end
      end
    end
    min
  end

end
