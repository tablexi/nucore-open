#
# This class encapsulates knowledge of the entire +Account+
# family/hierarchy that no one member of that family should have
class AccountManager
  #
  # An +Array+ of the #names of +Account+ classes that are used across facilities.
  GLOBAL_ACCOUNT_CLASSES=[ NufsAccount.name.to_s ]

  #
  # An +Array+ of the #names of +Account+ classes that are limited to individual facilities.
  FACILITY_ACCOUNT_CLASSES=[ CreditCardAccount.name.to_s, PurchaseOrderAccount.name.to_s ]
end