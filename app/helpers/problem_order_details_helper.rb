module ProblemOrderDetailsHelper
  def problem_order_date(order_detail, reservation_list_page)
    date =
      if reservation_list_page
        order_detail.reservation.actual_start_at
      else
        order_detail.order.ordered_at
      end

    human_datetime(date)
  end
end
