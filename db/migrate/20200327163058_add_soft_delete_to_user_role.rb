class AddSoftDeleteToUserRole < ActiveRecord::Migration[5.2]
  def change
    change_table :user_roles do |t|
      t.datetime :deleted_at, index: true
    end
  end
end
