class CreateFacilityAccounts < ActiveRecord::Migration
  def self.up
    create_table :facility_accounts do |t|
      t.references :facility,       :null => false
      t.string     :account_number, :null => false, :limit => 50
      t.boolean    :is_active,      :null => false
      t.integer    :created_by,     :null => false
      t.datetime   :created_at,     :null => false
    end
    execute "ALTER TABLE facility_accounts add CONSTRAINT fk_facilities FOREIGN KEY (facility_id) REFERENCES facilities (id)"
    
    Facility.find(:all).each do |f|
      execute "INSERT INTO facility_accounts (id, facility_id, account_number, is_active, created_at, created_by) VALUES (FACILITY_ACCOUNTS_SEQ.nextVal, #{f.id}, #{f.account}, 1, SYSDATE, 1)"
    end
    
    remove_column :facilities, :account
    
    add_column :products, :facility_account_id, :integer, :null => true
    execute "ALTER TABLE products add CONSTRAINT fk_facility_accounts FOREIGN KEY (facility_account_id) REFERENCES facility_accounts (id)"    
    execute "UPDATE products p SET p.facility_account_id = (SELECT id FROM facility_accounts fa WHERE fa.facility_id = p.facility_id)"
    change_column :products, :facility_account_id, :integer, :null => false
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
