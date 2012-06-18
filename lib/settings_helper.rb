module SettingsHelper
  def self.has_review_period?
    Settings.billing.review_period > 0
  end
end