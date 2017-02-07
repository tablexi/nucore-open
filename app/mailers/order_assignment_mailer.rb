class OrderAssignmentMailer < BaseMailer

  def notify_assigned_user(order_details)
    return if order_details.blank?

    @order_details = Array(order_details)
    @user = @order_details.first.assigned_user

    mail(to: @user.email, subject: subject)
  end

  private

  def subject
    text("views.order_assignment_mailer.notify_assigned_user.subject")
  end

end
