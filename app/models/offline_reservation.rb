class OfflineReservation < Reservation
  validates :admin_note, presence: true

  belongs_to :product

  scope :current, -> { where(reserve_end_at: nil).where("reserve_start_at < ?", Time.current) }

  def admin?
    true
  end

  def as_calendar_object(options = nil)
    if reserve_end_at.present?
      calendar_hash_defaults.merge(
        "end" => I18n.l(reserve_end_at, format: :calendar),
      )
    else
      calendar_hash_defaults.merge("editPath" => edit_path)
    end
  end

  private

  def calendar_hash_defaults
    {
      "admin" => true,
      "allDay" => false,
      "offline" => true,
      "product" => product.name,
      "start" => I18n.l(reserve_start_at, format: :calendar),
      "title" => "Offline\n#{admin_note}",
    }
  end

  def edit_path
    Rails.application.routes.url_helpers.edit_facility_instrument_offline_reservation_path(facility, product, self)
  end

end
