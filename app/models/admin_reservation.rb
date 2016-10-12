class AdminReservation < Reservation

  include ActiveModel::ForbiddenAttributesProtection

  validates :category, presence: true

  belongs_to :product

  # TODO: Move admin parts of Reservation here

end
