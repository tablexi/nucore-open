# frozen_string_literal: true

class UpdateDurationRateRateAndSubsidyToPerMinuteValues < ActiveRecord::Migration[7.0]
  class DurationRate < ApplicationRecord; end

  def change
    DurationRate.update_all("rate = rate / 60.0, subsidy = subsidy / 60.0")
  end
end
