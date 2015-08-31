class PricePolicyBuilder
  attr_reader :product, :start_date

  delegate :facility, to: :product

  def self.get(product, start_date)
    self.new(product, start_date).get_price_policies
  end

  def initialize(product, start_date)
    @product = product
    @start_date = start_date
  end

  def get_price_policies
    return [] unless editable?
    facility.price_groups.map do |price_group|
      policy_for_price_group(price_group)
    end
  end

  private

  def editable?
    original_price_policies.empty? || original_price_policies_editable?
  end

  def policy_for_price_group(price_group)
    groups_with_policy[price_group] || new_price_policy(price_group)
  end

  def new_price_policy(price_group)
    model_class.new(
      price_group_id: price_group.id,
      product_id: product.id,
      can_purchase: false,
    )
  end

  def groups_with_policy
    @groups_with_policy ||= original_price_policies_hash
  end

  def original_price_policies_hash
    original_price_policies.map do |price_policy|
      [price_policy.price_group, price_policy]
    end.to_h
  end

  def model_class
    @model_class ||= "#{product.class}PricePolicy".constantize
  end

  def original_price_policies_editable?
    original_price_policies.all?(&:editable?)
  end

  def price_policies_for_start_date
    product.price_policies.for_date(start_date)
  end

  def original_price_policies
    @original_price_policies ||= price_policies_for_start_date || []
  end
end
