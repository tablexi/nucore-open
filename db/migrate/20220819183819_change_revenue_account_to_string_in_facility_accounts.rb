class ChangeRevenueAccountToStringInFacilityAccounts < ActiveRecord::Migration[6.1]
  def up
    change_column :facility_accounts, :revenue_account, :string
  end

  def down
    change_column :facility_accounts, :revenue_account, :integer
  end
end
