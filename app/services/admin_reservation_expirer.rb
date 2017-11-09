class AdminReservationExpirer

  def expire!
    expired_reservations.destroy_all
  end

  # private

  def expired_reservations
    AdminReservation.where("subtime(reserve_start_at, MAKETIME(expires_mins_before div 60,expires_mins_before mod 60,0)) < ?", Time.current)
  end

end
