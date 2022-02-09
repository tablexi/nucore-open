class AdjustPricePolicyUsageRatePrecision < ActiveRecord::Migration[6.0]
  def change
    change_column :price_policies, :usage_rate, :decimal, precision: 16, scale: 8
  end
end
