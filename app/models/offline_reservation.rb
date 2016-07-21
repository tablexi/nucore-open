class OfflineReservation < Reservation

  include ActiveModel::ForbiddenAttributesProtection

  validates :admin_note, presence: true

  belongs_to :product

  scope :current, -> { where(reserve_end_at: nil).where("reserve_start_at < ?", Time.current) }

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
    if reserve_end_at.present?
      super
    else
      "#{I18n.l(reserve_start_at)} -"
    end
  end

end
