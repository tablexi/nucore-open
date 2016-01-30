module SplitAccounts
  class SplitAccount < Account

    has_many :splits, class_name: "SplitAccounts::Split", foreign_key: :parent_split_account_id, inverse_of: :parent_split_account
    has_many :subaccounts, through: :splits

    validate :valid_percent_total
    validate :one_split_has_extra_penny

    accepts_nested_attributes_for :splits, allow_destroy: true

    def valid_percent_total
      if percent_total != 100
        errors.add(:splits, :percent_total)
      end
    end

    def percent_total
      splits.reduce(0) { |sum, split| sum + split.percent }
    end

    def one_split_has_extra_penny
      if extra_penny_count != 1
        errors.add(:splits, :only_one_extra_penny)
      end
    end

    def extra_penny_count
      splits.select(&:extra_penny?).size
    end

    # Stopped using SQL because that didn't seem to work until the built splits
    # and subaccounts were created.
    #
    # SQL version:
    #   subaccounts.where("expires_at IS NOT NULL").order(expires_at: :asc).first
    #
    def earliest_expiring_subaccount
      subaccounts = splits.map{ |split| split.subaccount }.select(&:expires_at)
      subaccounts.sort_by(&:expires_at).first
    end

    def recreate_journal_rows_on_order_detail_update?
      true
    end

  end
end
