class ControlDevice < ActiveRecord::Base

  belongs_to :secure_room
  has_many :card_readers

end
