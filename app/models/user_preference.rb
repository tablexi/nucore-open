class UserPreference < ActiveRecord::Base

  belongs_to :user
  validates :name, :value, presence: true

  OPTIONS = {
    "Facility Home Page" => ["Dashboard", "Timeline View"],
  }.freeze

end
