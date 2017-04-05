module SecureRooms

  class Event < ActiveRecord::Base

    belongs_to :card_reader
    belongs_to :user

    # TODO: We aren't certain if events will be used only for scan events with
    #       CardReader/User present, so there aren't yet validations.
    validates :occurred_at, presence: true

  end

end
