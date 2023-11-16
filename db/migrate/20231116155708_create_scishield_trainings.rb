class CreateScishieldTrainings < ActiveRecord::Migration[7.0]
  def change
    create_table :scishield_trainings do |t|
      t.integer :user_id
      t.string :course_name

      t.timestamps
    end
  end
end
