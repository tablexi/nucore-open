class AddArNumberToAccounts < ActiveRecord::Migration
  def change
    change_table :accounts do |t|
      t.string :ar_number
    end
  end
end
