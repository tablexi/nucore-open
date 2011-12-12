class CreateNucsDepartments < ActiveRecord::Migration

  def self.up
    create_table(:nucs_departments, :force => true) do |t|
      t.column(:value, :string, :limit => 16, :null => false)
      t.column(:auxiliary, :string, :limit => 512)
    end

    add_index(:nucs_departments, :value)
  end


  def self.down
    remove_index(:nucs_departments, :value)
    drop_table(:nucs_departments)
  end

end