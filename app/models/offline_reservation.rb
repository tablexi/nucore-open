class OfflineReservation < Reservation

  validates :admin_note, presence: true

  belongs_to :product

  scope :current, -> { where(reserve_end_at: nil).where("reserve_start_at < ?", Time.current) }

  def admin?
    true
  end

  def admin_removable?
    false
  end

  def to_s
    self.class.model_name.human + " " + I18n.l(reserve_start_at)
  end

end
