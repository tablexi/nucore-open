module GeneralReportsHelper

  def canceled_by_name(reservation)
    return t('reports.fields.auto_cancel_name') if reservation.canceled_by == 0
    reservation.canceled_by_user.try :full_name
  end

end
