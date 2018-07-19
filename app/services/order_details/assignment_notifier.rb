module OrderDetails

  class AssignmentNotifier < SimpleDelegator

    def notify
      if SettingsHelper.feature_on?(:order_assignment_notifications) && assigned_user_changed?
        OrderAssignmentMailer.notify_assigned_user(self).deliver_now
      end
    end

    private

    def assigned_user_changed?
      assigned_user_id_previously_changed? && assigned_user.present?
    end

  end

end
