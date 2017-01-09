class Notifier < ActionMailer::Base

  include DateHelper
  add_template_helper ApplicationHelper
  add_template_helper TranslationHelper
  add_template_helper OrdersHelper
  add_template_helper ViewHookHelper

  default from: Settings.email.from, content_type: "multipart/alternative"

  # Welcome user, login credentials.  CC to PI and Department Admin.
  # Who created the account.  How to update.
  def new_user(args)
    @user = args[:user]
    @password = args[:password]
    send_nucore_mail args[:user].email, text("views.notifier.new_user.subject")
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

  def order_notification(order, recipient)
    @order = order
    send_nucore_mail recipient, text("views.notifier.order_notification.subject"), template_name: "order_receipt", reply_to: reply_to_email(@order, @order.facility)
  end

  # Custom order forms send out a confirmation email when filled out by a
  # customer. Customer gets one along with PI/Admin/Lab Manager.
  def order_receipt(args)
    @user = args[:user]
    @order = args[:order]
    @greeting = text("views.notifier.order_receipt.intro")
    send_nucore_mail args[:user].email, text("views.notifier.order_receipt.subject"), reply_to: reply_to_email(@order, @order.facility)
  end

  def review_orders(args)
    @user = User.find(args[:user_id])
    @accounts = Account.find(args[:account_ids]).map(&:account_list_item).to_sentence
    send_nucore_mail @user.email, text("views.notifier.review_orders.subject")
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
    send_nucore_mail args[:user].email, text("views.notifier.statement.subject", facility: @facility), reply_to: reply_to_email(@statement.order_details.first.order, @facility)
  end

  def order_detail_status_change(order_detail, old_status, new_status, to)
    @order_detail = order_detail
    @old_status = old_status
    @new_status = new_status
    template = "order_status_changed_to_#{new_status.downcase_name}"
    send_nucore_mail to, t("views.notifier.#{template}.subject", order_detail: order_detail, user: order_detail.order.user, product: order_detail.product), template_name: template, reply_to: reply_to_email(order_detail.order, order_detail.facility)
  end

  private

  def attach_statement_pdf
    attachments[statement_pdf.filename] = {
      mime_type: "application/pdf",
      content: statement_pdf.render,
    }
  end

  def statement_pdf
    @statement_pdf ||= StatementPdfFactory.instance(@statement)
  end

  def send_nucore_mail(to, subject, template_name: nil, reply_to: nil)
    options = { subject: subject, to: to, template_name: template_name }
    options[:reply_to] = reply_to if reply_to
    mail(options)
  end

  def reply_to_email(order, facility)
    order.order_details.first.product.contact_email || facility.email
  end

end
