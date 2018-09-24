# frozen_string_literal: true

class ProblemOrderMailer < BaseMailer

  def notify_user(order_detail)
    @order_detail = order_detail
    @user = @order_detail.user
    mail(to: @user.email, subject: text("notify_user.subject", facility: @order_detail.facility.abbreviation))
  end

  protected

  def translation_scope
    "views.problem_order_mailer"
  end

end
