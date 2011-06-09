class CreateExternalServices < ActiveRecord::Migration
  def self.up
    create_table :external_services do |t|
      t.string :type
      t.string :location
    end
  end

  def self.down
  end
end
