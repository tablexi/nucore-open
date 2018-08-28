# frozen_string_literal: true

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

    def dispute_resolved_at_previously_was
      previous_changes[:dispute_resolved_at].first
    end

  end

end
