module SplitAccounts
  class SplitAccount < Account

    has_many :splits, class_name: "SplitAccounts::Split", foreign_key: :parent_split_account_id, inverse_of: :parent_split_account
    has_many :subaccounts, through: :splits

    validate :valid_percent_total
    validate :one_split_has_extra_penny
    validate :unique_split_subaccounts
    validate :more_than_one_split

    accepts_nested_attributes_for :splits, allow_destroy: true

    def valid_percent_total
      if percent_total != 100
        errors.add(:splits, :percent_total)
      end
    end

    def percent_total
      splits.reduce(0) do |sum, split|
        split.percent.present? ? sum + split.percent : sum
      end
    end

    def one_split_has_extra_penny
      if extra_penny_count != 1
        errors.add(:splits, :only_one_extra_penny)
      end
    end

    def unique_split_subaccounts
      if duplicate_subaccounts?
        errors.add(:splits, :duplicate_subaccounts)
      end
    end

    def extra_penny_count
      splits.select(&:extra_penny?).size
    end

    def duplicate_subaccounts?
      splits.map(&:subaccount_id)
        .group_by { |subaccount_id| subaccount_id }
        .reject { |key, value| key.blank? }
        .any? { |key, value| value.size > 1 }
    end

    def more_than_one_split
      if splits.size <= 1
        errors.add(:splits, :more_than_one_split)
      end
    end

    # Stopped using SQL because that didn't seem to work until the built splits
    # and subaccounts were created. `subaccounts` has_many :through seems to not
    # work here, either
    #
    # SQL version:
    #   subaccounts.where("expires_at IS NOT NULL").order(expires_at: :asc).first
    #
    def earliest_expiring_subaccount
      splits.map(&:subaccount).compact.min_by(&:expires_at)
    end

    def recreate_journal_rows_on_order_detail_update?
      true
    end

  end
end
