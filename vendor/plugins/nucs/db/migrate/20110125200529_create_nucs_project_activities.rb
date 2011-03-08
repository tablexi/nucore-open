class CreateNucsProjectActivities < ActiveRecord::Migration
  
  def self.up
    create_table(:nucs_project_activities) do |t|
      t.column(:project, :string, :limit => 16, :null => false)
      t.column(:activity, :string, :limit => 16, :null => false)
      t.column(:auxiliary, :string, :limit => 512)
    end

    add_index(:nucs_project_activities, :project)
    add_index(:nucs_project_activities, :activity)
  end


  def self.down
    remove_index(:nucs_project_activities, :activity)
    remove_index(:nucs_project_activities, :project)
    drop_table(:nucs_project_activities)
  end
  
end
