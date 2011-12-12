class CreateNucsChartField1s < ActiveRecord::Migration
  
  def self.up
    create_table(:nucs_chart_field1s, :force => true) do |t|
      t.column(:value, :string, :limit => 16, :null => false)
      t.column(:auxiliary, :string, :limit => 512)
    end

    add_index(:nucs_chart_field1s, :value)
  end


  def self.down
    remove_index(:nucs_chart_field1s, :value)
    drop_table(:nucs_chart_field1s)
  end
  
end
