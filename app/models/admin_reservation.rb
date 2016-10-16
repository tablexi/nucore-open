class AdminReservation < Reservation

  include ActiveModel::ForbiddenAttributesProtection

  CATEGORIES = %w(
    maintenance
    training
    reserved_for_staff
    instrument_unavailable
    other
  ).freeze

  belongs_to :product

  validates :category,
            inclusion: { in: CATEGORIES, allow_blank: true }

  # TODO: Move admin parts of Reservation here

  def admin?
    true
  end

end
