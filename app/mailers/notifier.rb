class Notifier < ActionMailer::Base

  include DateHelper
  add_template_helper ApplicationHelper
  add_template_helper TranslationHelper
  add_template_helper OrdersHelper
  add_template_helper ViewHookHelper

  default from: Settings.email.from, content_type: "multipart/alternative"

  # Welcome user, login credentials
  def new_user(user:, password:)
    @user = user
    @password = password
    send_nucore_mail @user.email, text("views.notifier.new_user.subject")
  end

  # Changes to the user affecting the PI or department will alert their
  # PI, the Dept Admins, and Lab Manager.
  def user_update(args)
    @user = args[:user]
    @account = args[:account]
    @created_by = args[:created_by]
    send_nucore_mail @account.owner.user.email, text("views.notifier.user_update.subject")
  end

  # Any changes to the financial accounts will alert the PI(s), admin(s)
  # when it is not them making the change. Adding someone to any role of a
  # financial account as well. Roles: Order, Admin, PI.
  def account_update(args)
    @user = args[:user]
    @account = args[:account]
    send_nucore_mail args[:user].email, text("views.notifier.account_update.subject")
  end

  # Notifies the specified recipient if an order is placed including a product
  def product_order_notification(order_detail, recipient)
    @order = order_detail.order
    @order_detail = OrderDetailPresenter.new(order_detail)
    attach_reservation_ical(order_detail.reservation)
    send_nucore_mail recipient, text("views.notifier.product_order_notification.subject", product: order_detail.product)
  end

  def order_notification(order, recipient)
    @order = order
    attach_each_order_ical(@order)
    send_nucore_mail recipient, text("views.notifier.order_notification.subject"), "order_receipt"
  end

  # Custom order forms send out a confirmation email when filled out by a
  # customer. Customer gets one along with PI/Admin/Lab Manager.
  def order_receipt(args)
    @user = args[:user]
    @order = args[:order]
    @greeting = text("views.notifier.order_receipt.intro")
    attach_each_order_ical(@order)
    send_nucore_mail args[:user].email, text("views.notifier.order_receipt.subject")
  end

  def review_orders(user_id:, account_ids:, facility: Facility.cross_facility)
    @user = User.find(user_id)
    @accounts = Account.find(account_ids)
    @facility = facility
    send_nucore_mail @user.email, text("views.notifier.review_orders.subject", abbreviation: @facility.abbreviation)
  end

  # Billing sends out the statement for the month. Appropriate users get
  # their version of usage.
  # args = :user, :account, :facility
  def statement(args)
    @user = args[:user]
    @facility = args[:facility]
    @account = args[:account]
    @statement = args[:statement]
    attach_statement_pdf
    send_nucore_mail args[:user].email, text("views.notifier.statement.subject", facility: @facility)
  end

  def order_detail_status_change(order_detail, old_status, new_status, to)
    @order_detail = order_detail
    @old_status = old_status
    @new_status = new_status
    template = "order_status_changed_to_#{new_status.downcase_name}"
    send_nucore_mail to, t("views.notifier.#{template}.subject", order_detail: order_detail, user: order_detail.order.user, product: order_detail.product), template
  end

  private

  def attach_each_order_ical(order)
    order.order_details.map(&:reservation).compact.each do |reservation|
      attach_reservation_ical(reservation)
    end
  end

  def attach_reservation_ical(reservation)
    return unless reservation.present?

    calendar = ReservationCalendar.new(reservation)
    attachments[calendar.filename] = {
      mime_type: "text/calendar", content: [calendar.to_ical]
    }
  end

  def attach_statement_pdf
    attachments[statement_pdf.filename] = {
      mime_type: "application/pdf",
      content: statement_pdf.render,
    }
  end

  def statement_pdf
    @statement_pdf ||= StatementPdfFactory.instance(@statement)
  end

  def send_nucore_mail(to, subject, template_name = nil)
    mail(subject: subject, to: to, template_name: template_name)
  end

end
