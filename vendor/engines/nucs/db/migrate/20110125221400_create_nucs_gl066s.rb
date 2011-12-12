class CreateNucsGl066s < ActiveRecord::Migration
  
  def self.up
    create_table(:nucs_gl066s, :force => true) do |t|
      t.column(:budget_period, :string, :limit => 8, :null => false)
      t.column(:fund, :string, :limit => 8, :null => false)
      t.column(:department, :string, :limit => 16, :null => false)
      t.column(:project, :string, :limit => 16, :null => false)
      t.column(:activity, :string, :limit => 16, :null => false)
      t.column(:account, :string, :limit => 16, :null => false)
      t.column(:starts_at, :datetime)
      t.column(:expires_at, :datetime)
    end

    add_index(:nucs_gl066s, :fund)
    add_index(:nucs_gl066s, :department)
    add_index(:nucs_gl066s, :project)
    add_index(:nucs_gl066s, :activity)
    add_index(:nucs_gl066s, :account)
  end


  def self.down
    remove_index(:nucs_gl066s, :fund)
    remove_index(:nucs_gl066s, :department)
    remove_index(:nucs_gl066s, :project)
    remove_index(:nucs_gl066s, :activity)
    remove_index(:nucs_gl066s, :account)
    drop_table(:nucs_gl066s)
  end
  
end
