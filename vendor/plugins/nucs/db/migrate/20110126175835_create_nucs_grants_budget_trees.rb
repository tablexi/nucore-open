class CreateNucsGrantsBudgetTrees < ActiveRecord::Migration

  def self.up
    create_table(:nucs_grants_budget_trees) do |t|
      t.column(:account, :string, :limit => 16, :null => false)
      t.column(:account_desc, :string, :limit => 32, :null => false)
      t.column(:roll_up_node, :string, :limit => 32, :null => false)
      t.column(:roll_up_node_desc, :string, :limit => 32, :null => false)
      t.column(:parent_node, :string, :limit => 32, :null => false)
      t.column(:parent_node_desc, :string, :limit => 32, :null => false)
      t.column(:account_effective_at, :date, :null => false)
      t.column(:tree, :string, :limit => 32, :null => false)
      t.column(:tree_effective_at, :date, :null => false)
    end

    add_index(:nucs_grants_budget_trees, :account)
  end


  def self.down
    remove_index(:nucs_grants_budget_trees, :account)
    drop_table(:nucs_grants_budget_trees)
  end
  
end
