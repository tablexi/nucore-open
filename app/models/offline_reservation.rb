class OfflineReservation < Reservation

  include ActiveModel::ForbiddenAttributesProtection

  validates :admin_note, presence: true

  belongs_to :product

  scope :current, -> { where(reserve_end_at: nil).where("reserve_start_at < ?", Time.current) }
  scope :offline_schedule_ids, -> { joins(:product).pluck(:schedule_id) }

  def admin?
    true
  end

  def admin_removable?
    false
  end

  def end_at_required?
    false
  end

  def to_s
    I18n.l(reserve_start_at)
  end

end
