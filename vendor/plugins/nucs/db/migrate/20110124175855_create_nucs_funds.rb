class CreateNucsFunds < ActiveRecord::Migration

  def self.up
    create_table(:nucs_funds) do |t|
      t.column(:value, :string, :limit => 8, :null => false)
      t.column(:auxiliary, :string, :limit => 512)
    end

    add_index(:nucs_funds, :value)
  end


  def self.down
    remove_index(:nucs_funds, :value)
    drop_table(:nucs_funds)
  end

end
