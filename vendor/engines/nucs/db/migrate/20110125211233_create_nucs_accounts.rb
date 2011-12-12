class CreateNucsAccounts < ActiveRecord::Migration
  
  def self.up
    create_table(:nucs_accounts, :force => true) do |t|
      t.column(:value, :string, :limit => 16, :null => false)
      t.column(:auxiliary, :string, :limit => 512)
    end

    add_index(:nucs_accounts, :value)
  end


  def self.down
    remove_index(:nucs_accounts, :value)
    drop_table(:nucs_accounts)
  end
  
end
