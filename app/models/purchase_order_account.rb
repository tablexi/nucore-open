class PurchaseOrderAccount < Account
  belongs_to :facility

  validates_presence_of   :account_number
end
