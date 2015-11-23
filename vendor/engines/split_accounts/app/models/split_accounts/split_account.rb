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

    # TODO: expire at same time as most recently expiring subaccount
    def set_expires_at!
      self.expires_at = Time.now + 1.year
    end

  end
end
