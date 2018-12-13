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
    assign_attributes && save
  end

  private

  def assign_attributes
    @price_policies.each do |price_policy|
      price_policy.assign_attributes(price_group_attributes(price_policy.price_group))
    end
  end

  def save
    ActiveRecord::Base.transaction do
      @price_policies.all?(&:save) || raise(ActiveRecord::Rollback)
    end
  end

  def price_group_attributes(price_group)
    permitted_price_group_attributes(price_group).merge(
      start_date: @start_date,
      expire_date: @expire_date,
    ).merge(permitted_common_params)
  end

  def permitted_price_group_attributes(price_group)
    @params["price_policy_#{price_group.id}"]&.permit(*permitted_params) || { can_purchase: false }
  end

  def permitted_common_params
    @params.permit(:charge_for, :note, :created_by_id)
  end

  def permitted_params
    [
      :can_purchase,
      :usage_rate,
      :usage_subsidy,
      :minimum_cost,
      :cancellation_cost,
      :unit_cost,
      :unit_subsidy,
    ].tap do |attributes|
      attributes << :full_price_cancellation if SettingsHelper.feature_on?(:charge_full_price_on_cancellation)
    end
  end

end
