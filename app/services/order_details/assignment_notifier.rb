module OrderDetails

  class AssignmentNotifier < SimpleDelegator

    def notify
      if SettingsHelper.feature_on?(:order_assignment_notifications) && assigned_user_changed?
        OrderAssignmentMailer.notify_assigned_user(__getobj__).deliver_later
      end
    end

    private

    def assigned_user_changed?
      assigned_user_id_previously_changed? && assigned_user.present?
    end

    def assigned_user_id_previously_changed?
      previous_changes.key?(:assigned_user_id)
    end

  end

end
