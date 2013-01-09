class Schedule < ActiveRecord::Base
  
  # Associations
  # --------
  belongs_to :facility

  has_many :products, :class_name => 'Instrument'
  has_many :reservations, :through => :products

  # Validations
  # --------
  validates_presence_of :facility
  
end
