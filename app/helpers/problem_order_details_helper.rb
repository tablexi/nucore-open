module ProblemOrderDetailsHelper
  def problem_order_date_header(reservation_list_page)
    if reservation_list_page
      t('.th.actual_start')
    else
      Order.human_attribute_name(:ordered_at)
    end
  end

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
