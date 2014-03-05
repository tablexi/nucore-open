require_relative 'ipp_converter'

#
# This class and it's usages can be removed after
# move to the new instrument price policy is complete
class IppUpdater

  attr_reader :converter, :details, :policies


  def initialize
    @converter = IppConverter.new
    @details = converter.convertible_details
    @policies = converter.convertible_policies
  end


  def update
    update_price_policies
    update_order_details
  end


  def update_price_policies
    policies.find_each do |policy|
      guard policy do
        update_price_policy policy
        puts "Policy #{policy.id} updated"
      end
    end
  end


  def update_price_policy(policy)
    policy.update_attributes! converter.new_policy_attributes_from(policy)
  end


  def update_order_details
    details.readonly(false).find_each do |detail|
      guard detail do
        update_order_detail detail
        puts "Detail #{detail.id} updated"
      end
    end
  end


  def update_order_detail(detail)
    price_policy = detail.price_policy
    actuals = price_policy.calculate_cost_and_subsidy_from_order_detail detail
    estimates = price_policy.estimate_cost_and_subsidy_from_order_detail detail
    detail.update_attributes!(
      actual_cost: actuals[:cost],
      actual_subsidy: actuals[:subsidy],
      estimated_cost: estimates[:cost],
      estimated_subsidy: estimates[:subsidy]
    )
  end


  def update_journaled_details(oid_to_attrs)
    details = OrderDetail.find oid_to_attrs.keys
    details.each {|od| od.update_attributes! oid_to_attrs[od.id]}
  end


  private

  def guard(obj)
    begin
      yield
    rescue => e
     puts converter.error_to_log(e, obj)
    end
  end

end
