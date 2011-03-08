class InstrumentStatus < ActiveRecord::Base
  belongs_to :instrument
  
  validates_numericality_of :instrument_id
  validates_inclusion_of :is_on, :in => [true, false]

  
  def status_string
    is_on? ? 'On' : 'Off'
  end
end