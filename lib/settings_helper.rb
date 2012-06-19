module SettingsHelper
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def fiscal_year_end(date=nil)
      date ||= Time.zone.now
      (fiscal_year_beginning(date) + 1.year- 1.day).end_of_day
    end

    def fiscal_year_beginning(date=nil)
      date ||= Time.zone.now
      fiscal_year_starts = fiscal_year(date.year) 
      date.to_time > fiscal_year_starts ? fiscal_year_starts : fiscal_year_starts - 1.year
    end

    def fiscal_year(year)
      Time.zone.parse("#{year}-#{Settings.financial.fiscal_year_begins}").beginning_of_day
    end
  end
  
end