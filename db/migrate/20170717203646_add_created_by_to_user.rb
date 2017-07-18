class AddCreatedByToUser < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.integer :created_by
    end
  end
end
