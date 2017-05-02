class AddSkipOrderFlag < ActiveRecord::Migration

  def change
    add_column :secure_rooms_events, :skip_order, :boolean
  end

end
