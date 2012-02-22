class AddInstrumentRestrictionLevels < ActiveRecord::Migration
  def self.up
    create_table :instrument_restriction_levels do |t|
      t.references :instrument, :null => false
      t.string :name
      t.timestamps
    end
    # have to use an abbreviated version of the name for oracle
    # because it only allows a maximum of 30 characters
    create_table :instr_restr_schedule_rules, :id => false do |t|
      t.references :instrument_restriction_level, :null => false
      t.references :schedule_rule, :null => false
    end
    add_column :product_users, :instrument_restriction_level_id, :int
  end

  def self.down
    drop_table :instrument_restriction_levels
    drop_table :instr_restr_schedule_rules
    remove_column :product_users, :instrument_restriction_level_id
  end
end
