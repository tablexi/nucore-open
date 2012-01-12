class InstrumentRestrictionLevel < ActiveRecord::Base
  belongs_to :instrument
  has_many :product_users, :dependent => :nullify
  has_many :users, :through => :product_users
  has_and_belongs_to_many :schedule_rules
  validates :instrument, :presence => true
  validates :name, :presence => true, :uniqueness => { :scope => :instrument_id }
  
end