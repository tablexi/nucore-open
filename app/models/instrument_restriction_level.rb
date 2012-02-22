class InstrumentRestrictionLevel < ActiveRecord::Base
  belongs_to :instrument
  has_many :product_users, :dependent => :nullify
  has_many :users, :through => :product_users
  
  # oracle has a maximum table name length of 30, so we have to abbreviate it down
  has_and_belongs_to_many :schedule_rules, :join_table => 'instr_restr_schedule_rules'
  
  validates :instrument, :presence => true
  validates :name, :presence => true, :uniqueness => { :scope => :instrument_id }
  
end