class OfflineReservation < Reservation
  validates :admin_note, presence: true

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
      "offline" => true,
      "title" => "Offline\n#{admin_note}",
      "product" => product.name,
      "editPath" => edit_path,
    }
  end

  private

  def edit_path
    Rails.application.routes.url_helpers.edit_facility_instrument_offline_reservation_path(facility, product, self)
  end

end
