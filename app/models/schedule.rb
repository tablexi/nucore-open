class Schedule < ActiveRecord::Base
  
  # Associations
  # --------
  belongs_to :facility

  has_many :products, :class_name => 'Instrument'
  has_many :reservations, :through => :products
  has_many :schedule_rules

  # Validations
  # --------
  validates_presence_of :facility
  
end
