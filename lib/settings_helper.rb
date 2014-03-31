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

  def self.relays_enabled_for_admin?
    setting "relays.#{Rails.env}.admin_enabled"
  end

  def self.relays_enabled_for_reservation?
    setting "relays.#{Rails.env}.reservation_enabled"
  end

  #
  # Used to query the +Settings+ under feature:
  # [_feature_]
  #   If you want to check setting 'feature.password_update_on'
  #   then this parameter would be :password_update
  def self.feature_on?(feature)
    Settings.feature.try(:"#{feature}_on")
  end

  #
  # Used to turn on an off a feature. Most useful for tests:
  # [_feature_]
  #   If you want to change 'feature.password_update_on'
  #   then this parameter would be :password_update
  # [_value_]
  #   If set to false, it will disable the feature
  def self.enable_feature(feature, value=true)
    Settings.feature.send(:"#{feature}_on=", !!value) # !! forces to boolean
  end

  #
  # Used for looking up a setting where parts of the chain might not be there.
  # Setting is accessed like "reservations.grace_period"
  def self.setting(setting)
    current = Settings
    setting.split('.').each do |s|
      current = current.try(:[], s)
    end
    current
  end
end
