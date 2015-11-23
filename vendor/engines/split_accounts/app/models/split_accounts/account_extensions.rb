module SplitAccounts
  module AccountExtensions

    extend ActiveSupport::Concern

    included do
      has_many :parent_splits, class_name: "SplitAccounts::Split", foreign_key: :subaccount_id, inverse_of: :subaccount
      has_many :parent_split_accounts, through: :parent_splits
    end

  end
end
