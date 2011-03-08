class EditsForInvoicingAndJournalingRefacting < ActiveRecord::Migration
  def self.up
    # update the account_transaction table
    remove_column :account_transactions, :facility_account_id
    add_column    :account_transactions, :statement_id, :integer, :null => true
    
    # remove statement_accounts as account_transactions now have a link back to the statement
    # add an invoice_date to statements
    drop_table :statement_accounts
    execute 'DELETE FROM statements'
    add_column :statements, :invoice_date, :datetime, :null => false

    # track individual journal rows
    drop_table   :journaled_accounts
    create_table :journal_rows do |t|
      t.integer   :journal_id,      :null => false
      t.integer   :order_detail_id, :null => false
      t.integer   :fund,            :null => false, :limit => 10
      t.integer   :dept,            :null => false, :limit => 10
      t.integer   :project,         :null => false, :limit => 10
      t.integer   :activity,        :null => true,  :limit => 10
      t.integer   :program,         :null => true,  :limit => 10
      t.integer   :account,         :null => false, :limit => 10
      t.decimal   :amount,          :null => false, :precision => 9, :scale => 2
      t.string    :description,     :null => true,  :limit => 200
      t.string    :reference,       :null => true,  :limit => 50
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
