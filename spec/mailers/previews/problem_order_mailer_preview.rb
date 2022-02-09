# frozen_string_literal: true

class ProblemOrderMailerPreview < ActionMailer::Preview

  def notify_user
    order_detail = Nucore::Database.random(Reservation.user.joins(:order_detail).merge(OrderDetail.complete)).order_detail
    ProblemOrderMailer.with(order_detail: order_detail).notify_user
  end

  def notify_user_with_resolution_option
    order_detail = Nucore::Database.random(Reservation.user.joins(:order_detail).merge(OrderDetail.complete)).order_detail
    ProblemOrderMailer.with(order_detail: order_detail).notify_user_with_resolution_option
  end

end
