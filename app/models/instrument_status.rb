class InstrumentStatus < ActiveRecord::Base
  belongs_to :instrument
  
  validates_numericality_of :instrument_id

  
  def status_string
    is_on? ? 'On' : 'Off'
  end
end
