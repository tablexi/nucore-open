class MigrateAndDropAccountTransactions < ActiveRecord::Migration
  def self.up
    OrderDetail.reset_column_information

    AccountTransaction.all.each do |at|
      od=at.order_detail
      st=at.statement

      if st
        st.finalized_at=at.finalized_at
        st.save!
        StatementRow.create!(:account => at.account, :statement => st, :amount => at.transaction_amount)
      end

      j_row=JournalRow.find_by_account_transaction_id(at.id)
      od.journal=j_row.journal if j_row
      od.statement=st
      od.fulfilled_at=at.created_at
      od.reconciled_note=at.reference
      od.save!
    end

    change_table :journal_rows do |t|
      t.remove :account_transaction_id
    end

    drop_table :account_transactions
  end

  def self.down
    change_table :journal_rows do |t|
      t.column :account_transaction_id, :integer
    end

    JournalRow.reset_column_information

    create_table :account_transactions do |t|
      t.integer  "account_id", :null => false
      t.integer  "facility_id", :null => false
      t.string   "description", :limit => 200
      t.decimal  "transaction_amount", :precision => 10, :scale => 2, :null => false
      t.integer  "created_by", :null => false
      t.datetime "created_at", :null => false
      t.string   "type", :limit => 50, :null => false
      t.datetime "finalized_at"
      t.integer  "order_detail_id"
      t.boolean  "is_in_dispute", :precision => 1,  :scale => 0, :null => false
      t.integer  "statement_id"
      t.string   "reference", :limit => 50
    end

    begin
      PurchaseAccountTransaction
    rescue NameError
      # class doesn't exist, so don't try to rollback data migration
    else

        OrderDetail.all.each do |od|
          st=od.statement
          st_rows=StatementRow.find_all_by_statement_id(st.id)
          oldest_st_row=nil

          st_rows.each do |row|
            oldest_st_row=row if oldest_st_row.nil? or row.created_at < oldest_st_row.created_at
          end

          # might be another subclass of AccountTransaction but this will do for now
          at=PurchaseAccountTransaction.new
          at.account=oldest_st_row.account
          at.facility=od.product.facility
          at.description="Order # #{od.to_s}"
          at.transaction_amount=oldest_st_row.amount
          at.created_by=st.created_by
          at.created_at=od.fulfilled_at
          at.finalized_at=st.finalized_at
          at.order_detail=od
          at.is_in_dispute=od.dispute_at && od.dispute_resolved_at.nil? ? 1 : 0
          at.statement=st
          at.reference=od.reconciled_note
          at.save!

          jr=JournalRow.find_by_order_detail_id(od.id)

          if jr
            jr.account_transaction_id=at.id
            jr.save!
          end
        end

    end
  end
end
