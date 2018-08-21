# frozen_string_literal: true

class ChangePricePoliciesRestrictPurchase < ActiveRecord::Migration

  def self.up
    execute "UPDATE price_policies SET restrict_purchase = 0 WHERE restrict_purchase IS NULL"
    change_column :price_policies, :restrict_purchase, :boolean, null: false
  end

  def self.down
    change_column :price_policies, :restrict_purchase, :boolean, null: true
  end

end
