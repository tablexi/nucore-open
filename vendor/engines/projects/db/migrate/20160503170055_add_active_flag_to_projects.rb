class AddActiveFlagToProjects < ActiveRecord::Migration

  def change
    add_column :projects, :active, :boolean, null: false, default: true
  end

end
