# frozen_string_literal: true

module SplitAccounts

  module AccountExtension

    extend ActiveSupport::Concern

    included do
      has_many :parent_splits, class_name: "SplitAccounts::Split", foreign_key: :subaccount_id, inverse_of: :subaccount
      has_many :parent_split_accounts, through: :parent_splits

      scope :excluding_split_accounts, -> { where("accounts.type != ?", "SplitAccounts::SplitAccount") }

      after_save :update_suspended_at_for_parent_split_accounts
      after_save :update_expires_at_for_parent_split_accounts
    end

    def update_suspended_at_for_parent_split_accounts
      if parent_split_accounts.any? && suspended_at_changed?
        parent_split_accounts.each do |split_account|
          split_account.set_suspended_at_from_subaccounts
          split_account.save
        end
      end
    end

    def update_expires_at_for_parent_split_accounts
      if parent_split_accounts.any? && expires_at_changed?
        parent_split_accounts.each do |split_account|
          split_account.set_expires_at_from_subaccounts
          split_account.save
        end
      end
    end

    # Allows all account types to appropriately respond to a method that is
    # specific to the SplitAccount account type.
    def splits
      []
    end

  end

end
