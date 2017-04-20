class ValidFulfilledAtDate
  include DateHelper

  # Returns nil if the date is invalid
  def self.parse(string)
    new(string).to_time
  end

  def initialize(string)
    @string = string
  end

  def to_time
    time = parse_usa_date(@string).try(:to_date)
    if valid_fulfilled_at?(time)
      time.beginning_of_day + 12.hours
    else
      nil
    end
  end

  private

  def valid_fulfilled_at?(date)
    date.present? &&
      date >= SettingsHelper.fiscal_year_beginning.to_date &&
      date <= Date.today
  end

end
