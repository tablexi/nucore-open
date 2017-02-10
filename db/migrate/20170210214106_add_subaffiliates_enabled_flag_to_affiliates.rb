class AddSubaffiliatesEnabledFlagToAffiliates < ActiveRecord::Migration
  def change
    add_column :affiliates, :subaffiliates_enabled, :boolean, default: false, null: false
  end
end
