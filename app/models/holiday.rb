# frozen_string_literal: true

class Holiday < ApplicationRecord

  validates_presence_of :date

  scope :future, -> { where('holidays.date >= ?', Time.current.to_date) }
  scope :on, -> (date) { where(date: date..date.end_of_day) }

end
