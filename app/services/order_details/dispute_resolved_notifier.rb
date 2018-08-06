module OrderDetails

  class DisputeResolvedNotifier < SimpleDelegator

    def notify
      if dispute_resolved_at_previously_changed? && dispute_resolved_at_previously_was.blank?

        users_to_notify.each do |user|
          OrderDetailDisputeMailer.dispute_resolved(order_detail: __getobj__, user: user).deliver_later
        end
      end
    end

    private

    def users_to_notify
      ([dispute_by] + account.administrators).compact.uniq
    end

    # In Rails 5, this method exists, but not in Rails 4.2.
    def dispute_resolved_at_previously_changed?
      previous_changes.key?(:dispute_resolved_at)
    end

    def dispute_resolved_at_previously_was
      previous_changes[:dispute_resolved_at].first
    end

  end

end
