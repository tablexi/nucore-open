class OfflineReservation < Reservation
  belongs_to :product

  scope :current, -> { where(reserve_end_at: nil).where("reserve_start_at < ?", Time.current) }

  def admin?
    true
  end

  def as_calendar_object(options = nil)
    {
      "admin" => true,
      "start" => I18n.l(reserve_start_at, format: :calendar),
      "end" => false,
      "allDay" => false,
      "title" => "Offline",
      "product" => product.name,
    }
  end

end
