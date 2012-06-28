module SettingsHelper

  def self.fiscal_year_end(date=nil)
    date ||= Time.zone.now
    (fiscal_year_beginning(date) + 1.year- 1.day).end_of_day
  end

  def self.fiscal_year_beginning(date=nil)
    date ||= Time.zone.now
    fiscal_year_starts = fiscal_year(date.year) 
    date.to_time >= fiscal_year_starts ? fiscal_year_starts : fiscal_year_starts - 1.year
  end

  def self.fiscal_year(year)
    Time.zone.parse("#{year}-#{Settings.financial.fiscal_year_begins}").beginning_of_day
  end

  def self.has_review_period?
    Settings.billing.review_period > 0
  end

  #
  # Used to query the +Settings+ under feature:
  # [_feature_]
  #   If you want to check setting 'feature.password_update_on'
  #   then this parameter would be :password_update
  def self.feature_on?(feature)
    Settings.feature.send(:"#{feature}_on")
  end

end