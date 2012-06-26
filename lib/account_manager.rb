#
# This class encapsulates knowledge of the entire +Account+
# family/hierarchy that no one member of that family should have
class AccountManager
  #
  # An +Array+ of the #names of +Account+ classes that are used across facilities.
  GLOBAL_ACCOUNT_CLASSES=[ NufsAccount.name ]

  #
  # An +Array+ of the #names of +Account+ classes that are limited to individual facilities.
  FACILITY_ACCOUNT_CLASSES=EngineManager.engine_loaded?(:c2po) ? [ CreditCardAccount.name, PurchaseOrderAccount.name ] : []

  #
  # An +Array+ of the #names of +Account+ classes whose +OrderDetail+s can be included on statements.
  STATEMENT_ACCOUNT_CLASSES=FACILITY_ACCOUNT_CLASSES

  #
  # Returns true if this app is using +Account+ classes that appear on statements, false otherwise
  def self.using_statements?
    !STATEMENT_ACCOUNT_CLASSES.empty?
  end
end