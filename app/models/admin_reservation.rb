class AdminReservation < Reservation

  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :product

  # TODO: Move admin parts of Reservation here

end
