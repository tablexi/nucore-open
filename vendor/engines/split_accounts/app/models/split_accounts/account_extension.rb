module SplitAccounts
  module AccountExtension

    extend ActiveSupport::Concern

    included do
      has_many :parent_splits, class_name: "SplitAccounts::Split", foreign_key: :subaccount_id, inverse_of: :subaccount
      has_many :parent_split_accounts, through: :parent_splits

      scope :excluding_split_accounts, -> { where("accounts.type != ?", "SplitAccounts::SplitAccount") }
    end

    # Allows all account types to appropriately respond to a method that is
    # specific to the SplitAccount account type.
    def splits
      []
    end

  end
end
