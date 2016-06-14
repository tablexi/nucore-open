class OfflineReservation < Reservation
  belongs_to :product

  def admin?
    true
  end
end
