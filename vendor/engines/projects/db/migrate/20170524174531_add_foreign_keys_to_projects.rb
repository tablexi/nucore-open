# frozen_string_literal: true

class AddForeignKeysToProjects < ActiveRecord::Migration

  def change
    add_index :order_details, :project_id
  end

end
