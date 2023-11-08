class ChangeAssociationsDurationRates < ActiveRecord::Migration[7.0]
  def up
    DurationRate.destroy_all

    change_table :duration_rates do |t|
      t.references :price_policy
    end

    remove_column :duration_rates, :price_group_id
  end

  def down
    change_table :duration_rates do |t|
      t.references :price_group
    end

    remove_column :duration_rates, :price_policy_id
  end
end
