# For having more conveniently named route helpers so you don't always
# have to include current_facility, etc.
module RoutesHelper
  def manage_order_detail_path(order_detail)
    manage_facility_order_order_detail_path(order_detail.facility, order_detail.order, order_detail)
  end

  def admin_order_detail_path(action, order_detail)
    send("#{action}_facility_order_order_detail_path", order_detail.facility, order_detail.order, order_detail)
  end

  def sign_out_user_path
    if current_facility.present?
      destroy_user_session_path(facility_id: current_facility.url_name)
    else
      destroy_user_session_path
    end
  end

  def statement_path(statement)
    facility_account_statement_path(current_facility, statement.account_id, statement, :format => :pdf)
  end
end
