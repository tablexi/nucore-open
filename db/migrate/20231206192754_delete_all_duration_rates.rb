class DeleteAllDurationRates < ActiveRecord::Migration[7.0]
  class DurationRate < ApplicationRecord; end

  def change
    DurationRate.delete_all
  end
end
