class UserPreference < ActiveRecord::Base

  belongs_to :user
  validates :name, :value, presence: true
  validates :name, uniqueness: { scope: :user_id }

  cattr_accessor(:options_list) { [] } # list of option classes

  def self.create_appropriate_user_preferences(user)
    options_list.each do |option_class|
      option = option_class.new(user)
      preference = user.user_preferences.find_or_initialize_by(name: option.name)
      preference.value ||= option.default_value
      preference.save
    end
  end

end
