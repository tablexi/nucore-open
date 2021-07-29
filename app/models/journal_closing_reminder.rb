# frozen_string_literal: true

# Admin staff can still close journals for about a week after the end of the fiscal year.
# This is known as the 'year end closing window' - the date range between the
# end of the fiscal year and the journal cutoff date for the last month of the fiscal year.
#
# For example:
#   With FY22 starting 09/01/21, the closing window would
#   start Sep 1, 2021 and end on the August 2021 cutoff date:
#   Sep 1, 2021 - Sep 8, 2021.
class JournalClosingReminder < ApplicationRecord
  include DateTimeInput::Model
  date_time_inputable :starts_at
  date_time_inputable :ends_at

  validates :message, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :starts_before_ends

  before_validation :update_ends_at_to_end_of_day

  scope :current, -> { where("starts_at < ? and ? < ends_at", Time.current, Time.current) }

  def past?
    ends_at < Time.current
  end

  private

  def starts_before_ends
    if starts_at && ends_at
      errors.add(:starts_at, :start_after_end) if ends_at <= starts_at
    end
  end

  def update_ends_at_to_end_of_day
    self.ends_at = self.ends_at&.end_of_day
  end
end
