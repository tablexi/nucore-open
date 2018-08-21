# frozen_string_literal: true

class PricePolicyUpdater

  def self.update_all(price_policies, start_date, expire_date, params)
    new(price_policies, start_date, expire_date, params).update_all
  end

  def self.destroy_all_for_product!(product, start_date)
    price_policies = product.price_policies.for_date(start_date)
    raise ActiveRecord::RecordNotFound if price_policies.none?
    new(price_policies, start_date).destroy_all!
  end

  def initialize(price_policies, start_date, expire_date = nil, params = nil)
    @price_policies = price_policies
    @start_date = start_date
    @expire_date = expire_date
    @params = params
  end

  def destroy_all!
    ActiveRecord::Base.transaction do
      @price_policies.destroy_all || raise(ActiveRecord::Rollback)
    end
  end

  def update_all
    update && save
  end

  private

  def update
    @price_policies.each do |price_policy|
      price_policy.attributes = price_group_attributes(price_policy.price_group)
    end
  end

  def save
    ActiveRecord::Base.transaction do
      @price_policies.all?(&:save) || raise(ActiveRecord::Rollback)
    end
  end

  def price_group_attributes(price_group)
    initial_price_group_attributes(price_group).tap do |attributes|
      attributes[:charge_for] = @params[:charge_for] if @params[:charge_for].present?
      attributes[:expire_date] = @expire_date
      attributes[:start_date] = @start_date
    end
  end

  def initial_price_group_attributes(price_group)
    @params["price_policy_#{price_group.id}"]&.permit(:can_purchase,
                                                      :usage_rate,
                                                      :usage_subsidy,
                                                      :minimum_cost,
                                                      :cancellation_cost,
                                                      :unit_cost,
                                                      :unit_subsidy) || { can_purchase: false }
  end

end
