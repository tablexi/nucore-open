# frozen_string_literal: true

class InstrumentStatus < ApplicationRecord

  belongs_to :instrument

  validates_numericality_of :instrument_id

  attr_accessor :error_message

  def status_string
    return error_message if error_message
    is_on? ? "On" : "Off"
  end

  def as_json(_options = {})
    {
      instrument_status: {
        created_at: created_at,
        instrument_id: instrument.id,
        is_on: is_on?,
        error_message: @error_message,
      },
    }
  end

end
