class ValidFulfilledAtDate

  include DateHelper

  def self.parse(string)
    new(string).to_time
  end

  def initialize(string)
    @string = string
  end

  # Returns nil if the date is invalid
  def to_time
    time = parse_usa_date(@string).try(:to_date)
    time.beginning_of_day + 12.hours if valid_fulfilled_at?(time)
  end

  private

  def valid_fulfilled_at?(date)
    date.present? &&
      date >= SettingsHelper.fiscal_year_beginning.to_date &&
      date <= Date.today
  end

end
