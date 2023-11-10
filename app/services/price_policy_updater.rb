# frozen_string_literal: true

class PricePolicyUpdater

  def self.update_all(product, price_policies, start_date, expire_date, params)
    new(product, price_policies, start_date, expire_date, params).update_all
  end

  def self.destroy_all_for_product!(product, start_date)
    price_policies = product.price_policies.for_date(start_date)
    raise ActiveRecord::RecordNotFound if price_policies.none?
    new(product, price_policies, start_date).destroy_all!
  end

  def initialize(product, price_policies, start_date, expire_date = nil, params = nil)
    @product = product
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
    if @product.is_a?(Instrument) && @product.duration_pricing_mode?
      validate_steps_and_rates && save_for_stepped_billing
    else
      assign_attributes && save
    end
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

  def assign_attributes_for_stepped_billing
    @price_policies.each do |price_policy|
      price_group_id = price_policy.price_group.id
      duration_rates = @params.dig("price_policy_#{price_group_id}", "duration_rates_attributes")

      if duration_rates.present?
        duration_rates.values.each_with_index do |dr, index|
          if dr["rate"].present? || dr["subsidy"].present?
            # There is no rate_start_id in the params when rate starts are first being added.
            # In that case we need to use the rate_start_index to grab the rate_start_id,
            # which should have been persisted as part of the call to save_product.
            fallback_rate_start = @product.rate_starts[dr["rate_start_index"].to_i]&.id
            rate_start_id = dr["rate_start_id"].present? ? dr["rate_start_id"] : fallback_rate_start

            duration_rates["#{index}"].merge! ({ rate_start_id: rate_start_id, price_policy_id: price_policy.id })
          elsif dr[:id].present? && DurationRate.where(id: dr[:id]).present?
            duration_rates[index.to_s].merge! ({ _destroy: '1' })
          else
            duration_rates.delete(index.to_s)
          end
        end
      end
    end

    @price_policies.each do |price_policy|
      price_policy.assign_attributes(price_group_attributes(price_policy.price_group))
    end
  end

  def validate_steps_and_rates
    rate_starts_params = permitted_product_params[:rate_starts_attributes]

    rate_starts_length = rate_starts_params ? rate_starts_params.values.filter { |rs| rs[:min_duration].present? }.length : 0

    valid_duration_rates = @price_policies.all? do |price_policy|
                              price_group_id = price_policy.price_group.id
                              duration_rates = @params.dig("price_policy_#{price_group_id}", "duration_rates_attributes")
                              duration_rates_length = duration_rates.present? ? duration_rates.values.filter { |dr| dr[:rate].present? || dr[:subsidy].present? }.length : 0

                              duration_rates_length <= rate_starts_length
                            end

    unless valid_duration_rates
      @product.errors.add(:base, :missing_rate_starts, message: "Some rates or adjustments are missing Rate starts")
    end

    valid_duration_rates
  end

  def save_for_stepped_billing
    ActiveRecord::Base.transaction do
      (save_product && assign_attributes_for_stepped_billing && @price_policies.all?(&:save)) || raise(ActiveRecord::Rollback)
    end
  end

  def save_product
    keys_from_built_rate_starts = []

    rate_starts_params = permitted_product_params[:rate_starts_attributes].clone
    rate_starts_params.values.each_with_index do |dr, index|
      if dr[:min_duration].blank?
        if dr[:id].present?
          rate_starts_params["#{index}"].merge! ({ _destroy: '1' })
        else
          keys_from_built_rate_starts << "#{index}"
        end
      end
    end

    @product.update({ rate_starts_attributes: rate_starts_params.except(*keys_from_built_rate_starts) })
  end

  def price_group_attributes(price_group)
    permitted_price_group_attributes(price_group).merge(
      start_date: @start_date,
      expire_date: @expire_date,
    ).merge(permitted_common_params)
  end

  def permitted_price_group_attributes(price_group)
    price_policy_params = @params["price_policy_#{price_group.id}"]&.permit(*permitted_params)

    return { can_purchase: false } if price_policy_params.nil? || price_policy_params.keys.empty? || price_policy_params.keys == ["duration_rates_attributes"]

    price_policy_params
  end

  def permitted_common_params
    @params.permit(:charge_for, :note, :created_by_id)
  end

  def permitted_product_params
    @params[:product].permit(rate_starts_attributes: [:min_duration, :id])
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
      duration_rates_attributes: [
        :id,
        :subsidy,
        :rate,
        :price_policy_id,
        :rate_start_id,
        :rate_start_index,
        :_destroy
      ]
    ].tap do |attributes|
      attributes << :full_price_cancellation if SettingsHelper.feature_on?(:charge_full_price_on_cancellation)
    end
  end

end
