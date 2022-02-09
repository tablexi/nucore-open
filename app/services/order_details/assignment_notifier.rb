# frozen_string_literal: true

module OrderDetails

  class AssignmentNotifier < SimpleDelegator

    def notify
      if SettingsHelper.feature_on?(:order_assignment_notifications) && assigned_user_changed?
        OrderAssignmentMailer.with(order_details: __getobj__).notify_assigned_user.deliver_later
      end
    end

    private

    def assigned_user_changed?
      assigned_user_id_previously_changed? && assigned_user.present?
    end

  end

end
