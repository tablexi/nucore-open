class OrderAssignmentMailer < BaseMailer

  def notify_assigned_user(order_detail)
    @order_detail = order_detail
    @user = @order_detail.assigned_user

    mail(to: @user.email, subject: subject)
  end

  private

  def subject
    text("views.order_assignment_mailer.notify_assigned_user.subject")
  end

end
