class AccountConfig

  # Returns an array of all subclassed Account object names - including global,
  # per-facility, and statement account types.
  # Engines can append to this list.
  def account_types
    @account_types ||= [NufsAccount]
  end

  # Returns an array of subclassed Account object names that are available
  # across facilities. Derived from other lists.
  # Engines should NOT append to this list.
  def global_account_types
    account_types - facility_account_types
  end

  # Returns an array of subclassed Account object names that are only available
  # on a per-facility basis.
  # Engines can append to this list.
  def facility_account_types
    @facility_account_types ||= []
  end

  # Returns an array of subclassed Account object names that support statements.
  # Engines can append to this list.
  def statement_account_types
    @statement_account_types ||= []
  end

  # Given an subclassed `Account` name return a param-friendly string. Replaces
  # any backslashes with underscore to support namespaced class names.
  def account_type_to_param(account_type)
    account_type.to_s.underscore.gsub("/", "_")
  end

  # Returns an array of subclassed Account objects given a facility.
  # Facility can be a NullObject (used when not in the context of a facility)
  # and the NullObject always returns `true` for cross_facility?.
  def account_types_for_facility(facility)
    return account_types.select(&:cross_facility?) if facility.cross_facility?
    account_types
  end

  # Returns true if multiple account types are available
  def multiple_account_types?
    account_types.size > 1
  end

  # Returns true if statements are enabled. Some downstream repositories may
  # not use statements anywhere in the app.
  def using_statements?
    statement_account_types.present?
  end

  # Returns true if affiliates are enabled. Some downstream repositories may
  # not use affiliates anywhere in the app.
  def using_affiliates?
    using_statements?
  end

  # Returns true if this account type is limited to a single facility.
  def single_facility?(account_type)
    facility_account_types.map(&:to_s).include?(account_type.to_s.classify)
  end

  # Returns true if this account type can cross multiple facilities.
  def cross_facility?(account_type)
    global_account_types.map(&:to_s).include?(account_type.to_s.classify)
  end

end
