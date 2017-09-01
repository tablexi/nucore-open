class UserPreference < ActiveRecord::Base

  belongs_to :user
  validates :name, :value, presence: true

  # ex: { "Preference_Name" => ["Value1", "Value2"] }
  cattr_accessor(:options) { Hash.new([]) }

end
