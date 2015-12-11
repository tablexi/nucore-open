module SplitAccounts

  # Contains overrides for building a `SplitAccounts::SplitAccount` from params.
  # Dynamically called via the `AccountBuilder.for()` factory.
  class SplitAccountBuilder < AccountBuilder

    protected

    # Override strong_params for `build` account.
    def account_params_for_build
      [
        :account_number,
        :description,
        { splits_attributes: [:subaccount_id, :percent, :extra_penny, :_destroy] },
      ]
    end

    # Hooks into superclass's `build` method.
    def after_build
      set_expires_at
    end

    # Sets `expires_at` to match the earliest expiring subaccount.
    # Make sure this happens after the splits are built.
    def set_expires_at
      account.expires_at = account.earliest_expiring_subaccount.try(:expires_at)
      account
    end

  end
end
