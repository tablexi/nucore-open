class AddFieldsToAccounts < ActiveRecord::Migration
  def self.up
    add_column    :accounts, :expires_at,         :datetime,              :null => true
    execute "UPDATE accounts SET expires_at = to_date('2012/01/01:12:00:00AM', 'yyyy/mm/dd:hh:mi:ssam')"
    change_column :accounts, :expires_at,         :datetime,              :null => false
    
    add_column    :accounts, :name_on_card,       :string, :limit => 200, :null => true
    add_column    :accounts, :credit_card_number, :text,                  :null => true
    add_column    :accounts, :cvv,                :integer,               :null => true
    add_column    :accounts, :expiration_month,   :integer,               :null => true
    add_column    :accounts, :expiration_year,    :integer,               :null => true
    
    add_column    :accounts, :created_at,         :datetime,              :null => true
    execute "UPDATE accounts SET created_at = to_date('1981/09/15:12:00:00AM', 'yyyy/mm/dd:hh:mi:ssam')"
    change_column :accounts, :created_at,         :datetime,              :null => false
    
    add_column    :accounts, :created_by,         :integer,               :null => true
    execute "UPDATE accounts SET created_by = 0"
    change_column :accounts, :created_by,         :integer,               :null => false
    
    add_column    :accounts, :updated_at,         :datetime,              :null => true
    add_column    :accounts, :updated_by,         :integer,               :null => true
    
  end

  def self.down
    remove_column :accounts, :expires_at
    remove_column :accounts, :name_on_card
    remove_column :accounts, :credit_card_number
    remove_column :accounts, :cvv
    remove_column :accounts, :expiration_month
    remove_column :accounts, :expiration_year
    remove_column :accounts, :created_at
    remove_column :accounts, :created_by
    remove_column :accounts, :updated_at
    remove_column :accounts, :updated_by
  end
end
