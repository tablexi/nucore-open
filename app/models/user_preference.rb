class UserPreference < ActiveRecord::Base

  belongs_to :user
  validates :name, :value, presence: true
  validates :user_id, uniqueness: { scope: :name }

  # ex: { "Preference_Name" => ["Value1", "Value2"] }
  cattr_accessor(:options) { Hash.new([]) }

end
