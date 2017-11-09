class AdminReservationExpirer

  def expire!
    expired_reservations.destroy_all
  end

  private

  def expired_reservations
    AdminReservation.where("SUBTIME(reserve_start_at, MAKETIME(expires_mins_before DIV 60, expires_mins_before MOD 60, 0)) < ?", Time.current)
  end

end
