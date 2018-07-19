module OrderDetails

  class DisputeResolvedNotifier < SimpleDelegator

    def notify
      if dispute_resolved_at_previously_changed? && dispute_resolved_at_previously_was.blank?

        users_to_notify.each do |user|
          OrderDetailDisputeMailer.dispute_resolved(order_detail: self, user: user).deliver_now
        end
      end
    end

    private

    def users_to_notify
      ([dispute_by] + account.administrators).uniq
    end

    def dispute_resolved_at_previously_was
      previous_changes[:dispute_resolved_at].first
    end

  end

end
